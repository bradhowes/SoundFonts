// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os.log

/**
 Provider of a ConsolidatedConfig value. This normally comes from a configuration file. Access to the current value is
 to be done through a ConsolidatedConfigFileObserver which will run a closure when the configuration value changes.
 */
public final class ConsolidatedConfigProvider: NSObject {

  private let accessQueue = DispatchQueue(
    label: "ConsolidatedConfigProviderQueue",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .inherit,
    target: .global(qos: .userInitiated)
  )

  private let log: OSLog
  private var _config: ConsolidatedConfig?

  public let identity: Int = UUID().hashValue
  private let fileURL: URL
  private let coordinator: NSFileCoordinator
  private var idleTimer: Timer?
  private var lastReadTimestamp: Date?

  private var notificationCenterObservers = [NSObjectProtocol]()
  private var isRegistered: Bool { NSFileCoordinator.filePresenters.contains { $0 === self } }

  /// The value that comes from the document. Access to it is serialized via the `accessQueue` so it should be safe to
  /// access it from any thread.
  @objc dynamic public var config: ConsolidatedConfig? {
    get { accessQueue.sync { self._config } }
    set { accessQueue.sync { self._config = newValue } }
  }

  /**
   Obtain the configuration contents from a configuration file.

   - parameter inApp: `true` if running as an app, `false` if as an AUv3 app extension
   - parameter fileURL: the location for the document
   */
  public init(inApp: Bool, fileURL: URL) {
    self.log = Logging.logger("ConsolidatedConfigProvider[\(identity)]")
    self.coordinator = .init()
    self.fileURL = fileURL
    os_log(.debug, log: self.log, "init BEGIN - %{public}s", fileURL.description)

    super.init()

    NSFileCoordinator.addFilePresenter(self)
    registerNotifcations(inApp: inApp)
    os_log(.debug, log: self.log, "init END")
  }

  /**
   Load the configuration file. If the file does not exist, attempt to load an old-style version. If that fails then
   create a default confguration.

   NOTE: best to call this after everything else is connected and available -- see `Components.setMainViewController`
   */
  public func load() {
    if FileManager.default.fileExists(atPath: fileURL.path) {
      self.loadFromFile()
    } else if attemptLegacyLoad() {
      self.saveToFile()
    } else {
      config = .init()
      self.saveToFile()
    }
  }
}

extension ConsolidatedConfigProvider {

  /**
   Flag the configuration as having been changed so that the system will save it to disk.
   */
  public func markAsChanged() {
    if let idleTimer {
      idleTimer.invalidate()
    }

    // Save if there are no more changes after N seconds.
    idleTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
      self?.saveToFile()
      self?.idleTimer = nil
    }
  }

  private func attemptLegacyLoad() -> Bool {
    os_log(.debug, log: self.log, "attemptLegacyLoad")
    guard
      let soundFonts = LegacyConfigFileLoader<SoundFontCollection>.load(filename: "SoundFontLibrary.plist"),
      let favorites = LegacyConfigFileLoader<FavoriteCollection>.load(filename: "Favorites.plist"),
      let tags = LegacyConfigFileLoader<TagCollection>.load(filename: "Tags.plist")
    else {
      return false
    }

    os_log(.debug, log: self.log, "attemptLegacyLoad using legacy contents")
    self.config = ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags)

    return true
  }

  @objc private func saveToFile() {
    os_log(.info, log: self.log, "saveToFile - init")
    var err: NSError?
    coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &err) { destination in
      do {
        os_log(.info, log: self.log, "saveToFile - coordinated")
        let data = try self.config.encoded()
        try data.write(to: destination, options: .atomic)
        self.lastReadTimestamp = .init()
        os_log(.info, log: self.log, "saveToFile - end")
      } catch {
        os_log(.error, log: self.log, "saveToFile - error writing data: %{public}s", error.localizedDescription)
      }
    }
  }

  private func loadFromFile() {
    os_log(.info, log: self.log, "loadFromFile BEGIN")

    var err: NSError?
    coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &err) { destination in
      do {
        os_log(.info, log: self.log, "loadFromFile - coordinated")

        let doRead: Bool
        if let lastReadTimestamp {
          let attrs: [FileAttributeKey: Any]
          if #available(iOSApplicationExtension 16.0, *) {
            attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path())
          } else {
            attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
          }

          let when = attrs[.modificationDate] as? Date ?? .init()
          doRead = when > lastReadTimestamp
          os_log(
            .info,
            log: self.log,
            "loadFromFile - doRead: %d lastReadTimestamp: %ld when: %ld",
            doRead,
            lastReadTimestamp.timeIntervalSince1970,
            when.timeIntervalSince1970
          )
        } else {
          doRead = true
        }

        if doRead {
          let data = try Data(contentsOf: destination)
          self.config = try data.decoded()
          self.lastReadTimestamp = .init()
          NotificationCenter.default.post(name: .configFileChanged, object: nil)
        }
        os_log(.info, log: self.log, "loadFromFile - end")
      } catch {
        os_log(.error, log: self.log, "loadFromFile - error reading data: \(error)")
        self.handleLoadFailure()
      }
    }
    os_log(.debug, log: self.log, "loadFromFile END")
  }

  private func handleLoadFailure() {
    if !attemptLegacyLoad() {
      self.config = .init()
    }
    self.saveToFile()
    NotificationCenter.default.post(name: .configFileLoadFailure, object: nil)
  }
}

extension ConsolidatedConfigProvider {

  private func moveToBackground() {
    os_log(.info, log: self.log, "moveToBackground - init")
    if isRegistered {
      os_log(.info, log: self.log, "moveToBackground - unregistering")
      NSFileCoordinator.removeFilePresenter(self)
    }
  }

  private func moveToForeground() {
    os_log(.info, log: self.log, "moveToForeground - init")
    if !isRegistered {
      os_log(.info, log: self.log, "moveToForeground - registering")
      NSFileCoordinator.addFilePresenter(self)
      loadFromFile()
    }
  }

  private func registerNotifcations(inApp: Bool) {
    let mainQueue = OperationQueue.main

    if inApp {
      notificationCenterObservers.append(
        NotificationCenter.default.addObserver(
          forName: UIApplication.willEnterForegroundNotification,
          object: nil,
          queue: mainQueue
        ) { [weak self] _ in
          guard let self else { return }
          os_log(.info, log: self.log, "willEnterForegroundNotification")
          self.moveToForeground()
        }
      )

      notificationCenterObservers.append(
        NotificationCenter.default.addObserver(
          forName: UIApplication.didEnterBackgroundNotification,
          object: nil,
          queue: mainQueue
        ) { [weak self] _ in
          guard let self else { return }
          os_log(.info, log: self.log, "didEnterBackgroundNotification")
          self.moveToBackground()
        }
      )
    } else {
      notificationCenterObservers.append(
        NotificationCenter.default.addObserver(
          forName: .NSExtensionHostWillEnterForeground,
          object: nil,
          queue: mainQueue
        ) { [weak self] _ in
          guard let self else { return }
          os_log(.info, log: self.log, "NSExtensionHostWillEnterForeground")
          self.moveToForeground()
        }
      )

      notificationCenterObservers.append(
        NotificationCenter.default.addObserver(
          forName: .NSExtensionHostDidEnterBackground,
          object: nil,
          queue: mainQueue
        ) { [weak self] _ in
          guard let self else { return }
          os_log(.info, log: self.log, "ConfigFile.NSExtensionHostDidEnterBackground")
          self.moveToBackground()
        }
      )
    }
  }
}

extension ConsolidatedConfigProvider: NSFilePresenter {
  public var presentedItemOperationQueue: OperationQueue { OperationQueue.main }
  public var presentedItemURL: URL? { fileURL }

  public func presentedItemDidChange() {
    os_log(.info, log: self.log, "ConfigFile.presentedItemDidChange")
    loadFromFile()
  }
}
