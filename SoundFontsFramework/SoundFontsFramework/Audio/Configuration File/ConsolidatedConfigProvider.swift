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

  private let log: Logger
  private var _config: ConsolidatedConfig?

  public let identity: String
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
   - parameter identity: the unique tag assigned to this instance
   */
  public init(inApp: Bool, fileURL: URL, identity: String) {
    self.log = Logging.logger("ConsolidatedConfigProvider[\(identity)]")
    self.identity = identity
    self.coordinator = .init()
    self.fileURL = fileURL
    log.debug("init BEGIN - \(fileURL.description, privacy: .public)")

    super.init()

    NSFileCoordinator.addFilePresenter(self)
    registerNotifcations(inApp: inApp)
    log.debug("init END")
  }

  deinit {
    self.stopMonitoringFile()
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
    log.debug("attemptLegacyLoad")
    guard
      let soundFonts = LegacyConfigFileLoader<SoundFontCollection>.load(filename: "SoundFontLibrary.plist"),
      let favorites = LegacyConfigFileLoader<FavoriteCollection>.load(filename: "Favorites.plist"),
      let tags = LegacyConfigFileLoader<TagCollection>.load(filename: "Tags.plist")
    else {
      return false
    }

    log.debug("attemptLegacyLoad using legacy contents")
    self.config = ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags)

    return true
  }

  @objc private func saveToFile() {
    log.info("saveToFile - init")
    var err: NSError?
    coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &err) { destination in
      do {
        log.info("saveToFile - coordinated")
        let data = try self.config.encoded()
        try data.write(to: destination, options: .atomic)
        self.lastReadTimestamp = .init()
        log.info("saveToFile - end")
      } catch {
        log.error("saveToFile - error writing data: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  private func loadFromFile() {
    log.info("loadFromFile BEGIN")

    var err: NSError?
    coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &err) { destination in
      do {
        log.info("loadFromFile - coordinated")

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
        } else {
          doRead = true
        }

        if doRead {
          let data = try Data(contentsOf: destination)
          self.config = try data.decoded()
          self.lastReadTimestamp = .init()
          NotificationCenter.default.post(name: .configFileChanged, object: nil)
        }
        log.info("loadFromFile - end")
      } catch {
        log.error("loadFromFile - error reading data: \(error)")
        self.handleLoadFailure()
      }
    }
    log.debug("loadFromFile END")
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

  private func stopMonitoringFile() {
    log.info("stopMonitoringFile - init")
    if isRegistered {
      log.info("stopMonitoringFile - unregistering")
      NSFileCoordinator.removeFilePresenter(self)
    }
  }

  private func startMonitoringFile() {
    log.info("startMonitoringFile - init")
    if !isRegistered {
      log.info("startMonitoringFile - registering")
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
          log.info("willEnterForegroundNotification")
          self.startMonitoringFile()
        }
      )

      notificationCenterObservers.append(
        NotificationCenter.default.addObserver(
          forName: UIApplication.didEnterBackgroundNotification,
          object: nil,
          queue: mainQueue
        ) { [weak self] _ in
          guard let self else { return }
          log.info("didEnterBackgroundNotification")
          self.stopMonitoringFile()
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
          log.info("NSExtensionHostWillEnterForeground")
          self.startMonitoringFile()
        }
      )

      notificationCenterObservers.append(
        NotificationCenter.default.addObserver(
          forName: .NSExtensionHostDidEnterBackground,
          object: nil,
          queue: mainQueue
        ) { [weak self] _ in
          guard let self else { return }
          log.info("ConfigFile.NSExtensionHostDidEnterBackground")
          self.stopMonitoringFile()
        }
      )
    }
  }
}

extension ConsolidatedConfigProvider: NSFilePresenter {
  public var presentedItemOperationQueue: OperationQueue { OperationQueue.main }
  public var presentedItemURL: URL? { fileURL }

  public func presentedItemDidChange() {
    log.info("ConfigFile.presentedItemDidChange")
    loadFromFile()
  }
}
