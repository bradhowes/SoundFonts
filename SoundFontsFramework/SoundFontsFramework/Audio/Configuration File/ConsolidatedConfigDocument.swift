import UIKit
import os.log

/**
 Implementation of UIDocument that knows how to work with ConsolidatedConfig entities.
 */
final class ConsolidatedConfigDocument: UIDocument {
  private let log: OSLog

  private static let filename = "Consolidated.plist"
  private static var sharedConfigPath: URL { FileManager.default.sharedPath(for: filename) }

  // Pseudo-unique ID for this instance.
  private let identity: Int

  // The contents of the document
  @objc dynamic var contents: ConsolidatedConfig?

  private var notificationCenterObservers = [NSObjectProtocol]()
  private var isRegistered: Bool { NSFileCoordinator.filePresenters.contains { $0 === self } }

  /**
   Construct a new document container.

   - parameter identity: the identity to use for logging
   - parameter contents: the initial contents to sue
   */
  init(identity: Int, contents: ConsolidatedConfig? = nil, fileURL: URL? = nil) {
    let fileURL = fileURL ?? Self.sharedConfigPath
    let log = Logging.logger("ConsolidatedConfigDocument[\(identity)]")
    os_log(.debug, log: log, "init BEGIN - %{public}s", fileURL.description)
    self.log = log
    self.identity = identity
    self.contents = contents
    super.init(fileURL: fileURL)
    os_log(.debug, log: log, "init END")
  }

  deinit {
    os_log(.debug, log: log, "deinit")
  }

  /**
   Encode the configuration that will be written to the configuration file. The actual result type is `Data`.

   - parameter typeName: the name of the type to generate (ignored)
   - returns: result of the encoding to write out
   - throws exception if the encoding fails for any reason
   */
  override public func contents(forType typeName: String) throws -> Any {
    os_log(.debug, log: log, "contents - typeName: %{public}s", typeName)
    let data = try PropertyListEncoder().encode(contents)
    os_log(.debug, log: log, "contents - pending save of %d bytes", data.count)
    return data
  }

  /**
   Decode the raw data that was read from the configuration file.

   - parameter contents: the encoded contents to work with. Should be `Data` type.
   - parameter typeName: the name of the type that it represents
   - throws exception if the decoding fails for any reason
   */
  override public func load(fromContents contents: Any, ofType typeName: String?) throws {
    os_log(.debug, log: log, "load BEGIN - typeName: %{public}s", typeName ?? "nil")

    guard let data = contents as? Data else {
      os_log(.error, log: log, "load - given contents was not Data")
      createDefaultContents()
      return
    }

    guard let contents = try? PropertyListDecoder().decode(ConsolidatedConfig.self, from: data) else {
      os_log(.error, log: log, "load - failed to decode Data contents")
      createDefaultContents()
      return
    }

    os_log(.debug, log: log, "load decoded contents: %{public}s", contents.description)
    setContents(contents)
    os_log(.error, log: log, "load END")
  }

  /**
   Try to load old-style legacy files. This should be called if the initial `open` fails because the config file does
   not exist.
   */
  internal func attemptLegacyLoad(completion: ((Bool) -> Void)? = nil) {
    os_log(.debug, log: log, "attemptLegacyLoad")
    guard
      let soundFonts = LegacyConfigFileLoader<SoundFontCollection>.load(filename: "SoundFontLibrary.plist"),
      let favorites = LegacyConfigFileLoader<FavoriteCollection>.load(filename: "Favorites.plist"),
      let tags = LegacyConfigFileLoader<TagCollection>.load(filename: "Tags.plist")
    else {
      os_log(.debug, log: log, "failed to load one or more legacy files")
      createDefaultContents(completion: completion)
      return
    }

    os_log(.debug, log: log, "attemptLegacyLoad using legacy contents")
    setContents(
      ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags),
      saveOperation: .forCreating,
      completion: completion
    )
  }

  /**
   Create a new ConsolidatedConfig instance and use for the contents.
   */
  private func createDefaultContents(completion: ((Bool) -> Void)? = nil) {
    os_log(.debug, log: log, "createDefaultContents")
    self.setContents(
      ConsolidatedConfig(),
      saveOperation: .forCreating,
      completion: completion
    )
    NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
  }

  private func setContents(
    _ config: ConsolidatedConfig,
    saveOperation: SaveOperation? = nil,
    completion: ((Bool) -> Void)? = nil
  ) {
    os_log(.debug, log: log, "setContents")
    self.contents = config
    if let saveOperation {
      os_log(.debug, log: log, "setContents saving")
      self.save(to: fileURL, for: saveOperation) { [weak self] ok in
        guard let self else { return }
        os_log(.debug, log: self.log, "setContents - save ok %d", ok)
        if !ok {
          self.save(to: fileURL, for: .forOverwriting)
        }
        completion?(true)
      }
    } else {
      completion?(true)
    }
  }

  func moveToBackground() {
    os_log(.info, "ConfigFile.moveToBackground - init")
    if isRegistered {
      os_log(.info, "ConfigFile.moveToBackground - unregistering")
      self.close(completionHandler: nil)
      NSFileCoordinator.removeFilePresenter(self)
    }
  }

  func moveToForeground() {
    os_log(.info, "ConfigFile.moveToForeground - init")
    if !isRegistered {
      os_log(.info, "ConfigFile.moveToForeground - registering")
      NSFileCoordinator.addFilePresenter(self)
      // self.open(completionHandler: nil)
      // loadFromFile()
    }
  }

  private func registerNotifcations() {
    let mainQueue = OperationQueue.main

    notificationCenterObservers.append(
      NotificationCenter.default.addObserver(
        forName: .NSExtensionHostDidBecomeActive,
        object: nil,
        queue: mainQueue
      ) { [weak self] _ in
        os_log(.info, "ConfigFile.NSExtensionHostDidBecomeActive")
        self?.moveToForeground()
      }
    )

    notificationCenterObservers.append(
      NotificationCenter.default.addObserver(
        forName: .NSExtensionHostWillResignActive,
        object: nil,
        queue: mainQueue
      ) { [weak self] _ in
        os_log(.info, "ConfigFile.NSExtensionHostWillResignActive")
        self?.moveToBackground()
      }
    )
    //
    //    notificationCenterObservers.append(
    //      NotificationCenter.default.addObserver(
    //        forName: .NSExtensionHostDidEnterBackground,
    //        object: nil,
    //        queue: mainQueue
    //      ) { [weak self] _ in
    //        self?.moveToBackground()
    //      }
    //    )
    //
    //    notificationCenterObservers.append(
    //      NotificationCenter.default.addObserver(
    //        forName: .NSExtensionHostWillEnterForeground,
    //        object: nil,
    //        queue: mainQueue
    //      ) { [weak self] _ in
    //        self?.moveToForeground()
    //      }
    //    )
  }
}
