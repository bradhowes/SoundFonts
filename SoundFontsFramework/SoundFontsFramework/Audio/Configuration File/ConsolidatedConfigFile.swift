// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os.log

/// Extension of UIDocument that contains a ConsolidatedConfig value
public final class ConsolidatedConfigFile: UIDocument {
  private static let log = Logging.logger("ConsolidatedConfigFile")
  private var log: OSLog { Self.log }

  /// The file name for the consolidated document
  public static let filename = "Consolidated.plist"
  public static var sharedConfigPath: URL { FileManager.default.sharedPath(for: filename) }

  /// The value held in the document.
  public var config: ConsolidatedConfig!

  @objc dynamic public private(set) var restored: Bool = false

  private var monitor: ConfigFileConflictMonitor?

  /**
   Create new document that is stored at a particular location

   - parameter fileURL: the location for the document
   */
  override public init(fileURL: URL) {
    os_log(.info, log: Self.log, "init - fileURL: %{public}s", fileURL.absoluteString)
    super.init(fileURL: fileURL)
    self.monitor = ConfigFileConflictMonitor(configFile: self)
    DispatchQueue.main.async { self.restore() }
  }

  /**
   Restore from the contents of the file. If we fail, try to load the legacy version. If that fails, then we are left
   with the default collections.
   */
  private func restore() {
    os_log(.info, log: log, "restore - %{public}s", fileURL.path)
    self.open { ok in
      if !ok {
        os_log(.error, log: Self.log, "restore - failed to open - attempting legacy loading")

        // We are back on the main thread so do the loading in the background.
        DispatchQueue.global(qos: .userInitiated).async {
          self.attemptLegacyLoad()
        }
      }
    }
  }

  /**
   Encode the configuration that will be written to the configuration file. The actual result type is `Data`.

   - parameter typeName: the name of the type to generate (ignored)
   - returns: result of the encoding to write out
   - throws exception if the encoding fails for any reason
   */
  override public func contents(forType typeName: String) throws -> Any {
    os_log(.info, log: log, "contents - typeName: %{public}s", typeName)
    let contents = try PropertyListEncoder().encode(config)
    os_log(.info, log: log, "-- pending save of %d bytes", contents.count)
    return contents
  }

  /**
   Decode the raw data that was read from the configuration file.

   - parameter contents: the encoded contents to work with. Should be `Data` type.
   - parameter typeName: the name of the type that it represents
   - throws exception if the decoding fails for any reason
   */
  override public func load(fromContents contents: Any, ofType typeName: String?) throws {
    os_log(.info, log: log, "load - typeName: %{public}s", typeName ?? "nil")

    guard let data = contents as? Data else {
      os_log(.error, log: log, "given contents was not Data")
      createConfig()
      NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
      return
    }

    guard let config = try? PropertyListDecoder().decode(ConsolidatedConfig.self, from: data) else {
      os_log(.error, log: log, "failed to decode Data contents")
      createConfig()
      NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
      return
    }

    os_log(.info, log: log, "decoded contents: %{public}s", config.description)
    restoreConfig(config, save: false)
  }

  override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
    os_log(.info, log: log, "revert: %{public}s", url.path)
    self.close { ok in
      if !ok {
        os_log(.fault, log: Self.log, "revert - failed to close configuration file")
      }
    }
    super.revert(toContentsOf: url, completionHandler: completionHandler)
  }
}

extension ConsolidatedConfigFile {

  private func attemptLegacyLoad() {
    os_log(.info, log: log, "attemptLegacyLoad")
    guard
      let soundFonts = LegacyConfigFileLoader<SoundFontCollection>.load(filename: "SoundFontLibrary.plist"),
      let favorites = LegacyConfigFileLoader<FavoriteCollection>.load(filename: "Favorites.plist"),
      let tags = LegacyConfigFileLoader<TagCollection>.load(filename: "Tags.plist")
    else {
      os_log(.info, log: log, "failed to load one or more legacy files")
      createConfig()
      return
    }

    os_log(.info, log: log, "using legacy contents")
    restoreConfig(ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags), save: true)
  }

  private func createConfig() {
    os_log(.info, log: log, "initializeCollections")
    self.restoreConfig(ConsolidatedConfig(), save: true)
  }

  private func restoreConfig(_ config: ConsolidatedConfig, save: Bool) {
    os_log(.info, log: log, "restoreConfig")
    self.config = config
    self.restored = true
    if save {
      self.save(to: fileURL, for: .forOverwriting) { ok in
        if !ok {
          os_log(.fault, log: Self.log, "restoreConfig - failed to save configuration file")
        }
      }
    }
  }
}
