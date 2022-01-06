// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Originally, the SoundFonts app loaded three separate config files. However, there was risk of data corruption if the
 files were not updated all at once. This was made worse with the AUv3 component, since it and the app shared the same
 configuration files. This consolidated version stores everything in one file, so the risk of corruption is reduced.
 Further, it relies on UIDocument which provides a safe and reliable means of making changes and writing them to disk
 even if there are two or more parties doing it. For our case, we just let the last one win without notifying the user
 that there was even a conflict.
 */
public struct ConsolidatedConfig: Codable {
  private static let log = Logging.logger("ConsolidatedConfig")
  private var log: OSLog { Self.log }

  /// The collection of installed soundfonts and their presets
  public var soundFonts: SoundFontCollection
  /// The collection of created favorites
  public var favorites: FavoriteCollection
  /// The collection of tags that categorize the soundfonts
  public var tags: TagCollection
}

extension ConsolidatedConfig {

  /// Construct a new default collection, such as when the app is first installed or there is a problem loading a
  /// previously-saved file.
  public init() {
    os_log(.info, log: Self.log, "creating default collection")
    soundFonts = SoundFontsManager.defaultCollection
    favorites = FavoritesManager.defaultCollection
    tags = TagsManager.defaultCollection
  }
}

extension ConsolidatedConfig: CustomStringConvertible {

  /// Custom description for the instance
  public var description: String { "<Config \(soundFonts), \(favorites), \(tags)>" }
}

/// Extension of UIDocument that stores a ConsolidatedConfig value
public final class ConsolidatedConfigFile: UIDocument {
  private static let log = Logging.logger("ConsolidatedConfigFile")
  private var log: OSLog { Self.log }

  /// The file name for the consolidated document
  static let filename = "Consolidated.plist"

  public lazy var config: ConsolidatedConfig = ConsolidatedConfig()

  @objc dynamic public private(set) var restored: Bool = false {
    didSet {
      self.updateChangeCount(.done)
      self.save(to: fileURL, for: .forOverwriting)
    }
  }

  override public init(fileURL: URL) {
    os_log(.info, log: Self.log, "init - fileURL: %{public}s", fileURL.absoluteString)
    super.init(fileURL: fileURL)
  }

  public func save() {
    self.save(to: fileURL, for: .forOverwriting)
  }

  /// Load the contents of the file. If we fail, try to load the legacy version. If that fails, then we are left with
  /// the default collections.
  public func load() {
    os_log(.info, log: log, "load - %{public}s", fileURL.path)
    self.open { ok in
      if !ok {
        os_log(.error, log: Self.log, "failed to open - attempting legacy loading")

        // We are back on the main thread so do the loading in the background.
        DispatchQueue.global(qos: .userInitiated).async {
          self.attemptLegacyLoad()
        }
      }
    }
  }

  /**
   Encode the configuration that will be written to the configuration file. The actual result type is `Data` but it is
   type erased for the API.

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
      restoreConfig(ConsolidatedConfig())
      NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
      return
    }

    guard let config = try? PropertyListDecoder().decode(ConsolidatedConfig.self, from: data) else {
      os_log(.error, log: log, "failed to decode Data contents")
      restoreConfig(ConsolidatedConfig())
      NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
      return
    }

    os_log(.info, log: log, "decoded contents: %{public}s", config.description)
    restoreConfig(config)
  }

  /// FIXME
  override public func revert(toContentsOf url: URL, completionHandler: ((Bool) -> Void)? = nil) {
    completionHandler?(false)
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
      initializeCollections()
      return
    }

    os_log(.info, log: log, "using legacy contents")
    restoreConfig(ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags))
  }

  private func restoreConfig(_ config: ConsolidatedConfig) {
    os_log(.info, log: log, "restoreConfig")
    self.config = config
    self.restored = true
  }

  private func initializeCollections() {
    os_log(.info, log: log, "initializeCollections")
    self.restored = true
  }
}
