import UIKit
import os.log

/**
 Implementation of UIDocument that knows how to work with ConsolidatedConfig entities.
 */
final class ConfigFileDocument: UIDocument, Tasking {
  private static let log = Logging.logger("ConfigFileDocument")
  private var log: OSLog { Self.log }

  private static let filename = "Consolidated.plist"
  private static var sharedConfigPath: URL { FileManager.default.sharedPath(for: filename) }

  // Pseudo-unique ID for this instance.
  private let identity: Int

  // The contents of the document
  @objc dynamic var contents: ConsolidatedConfig?

  /**
   Construct a new document container.

   - parameter identity: the identity to use for logging
   - parameter contents: the initial contents to sue
   */
  init(identity: Int, contents: ConsolidatedConfig?) {
    os_log(.info, log: Self.log, "init BEGIN")
    self.identity = identity
    self.contents = contents
    super.init(fileURL: Self.sharedConfigPath)
    os_log(.info, log: Self.log, "init END")
  }

  deinit{
    os_log(.info, log: Self.log, "deinit")
  }

  /**
   Encode the configuration that will be written to the configuration file. The actual result type is `Data`.

   - parameter typeName: the name of the type to generate (ignored)
   - returns: result of the encoding to write out
   - throws exception if the encoding fails for any reason
   */
  override public func contents(forType typeName: String) throws -> Any {
    os_log(.info, log: log, "%d contents - typeName: %{public}s", identity, typeName)
    let data = try PropertyListEncoder().encode(contents)
    os_log(.info, log: log, "%d contents - pending save of %d bytes", identity, data.count)
    return data
  }

  /**
   Decode the raw data that was read from the configuration file.

   - parameter contents: the encoded contents to work with. Should be `Data` type.
   - parameter typeName: the name of the type that it represents
   - throws exception if the decoding fails for any reason
   */
  override public func load(fromContents contents: Any, ofType typeName: String?) throws {
    os_log(.info, log: log, "%d load BEGIN - typeName: %{public}s", identity, typeName ?? "nil")

    guard let data = contents as? Data else {
      os_log(.error, log: log, "%d load - given contents was not Data", identity)
      createDefaultContents()
      NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
      return
    }

    guard let contents = try? PropertyListDecoder().decode(ConsolidatedConfig.self, from: data) else {
      os_log(.error, log: log, "%d load - failed to decode Data contents", identity)
      createDefaultContents()
      NotificationCenter.default.post(Notification(name: .configLoadFailure, object: nil))
      return
    }

    os_log(.info, log: log, "%d load decoded contents: %{public}s", identity, contents.description)
    restoreContents(contents, save: false)

    os_log(.error, log: log, "%d load END", identity)
  }

  /**
   Try to load old-style legacy files. This should be called if the initial `open` fails because the config file does
   not exist.
   */
  internal func attemptLegacyLoad() {
    os_log(.info, log: log, "%d attemptLegacyLoad", identity)
    guard
      let soundFonts = LegacyConfigFileLoader<SoundFontCollection>.load(filename: "SoundFontLibrary.plist"),
      let favorites = LegacyConfigFileLoader<FavoriteCollection>.load(filename: "Favorites.plist"),
      let tags = LegacyConfigFileLoader<TagCollection>.load(filename: "Tags.plist")
    else {
      os_log(.info, log: log, "%d failed to load one or more legacy files", identity)
      createDefaultContents()
      return
    }

    os_log(.info, log: log, "%d attemptLegacyLoad using legacy contents", identity)
    restoreContents(ConsolidatedConfig(soundFonts: soundFonts, favorites: favorites, tags: tags), save: true)
  }

  /**
   Create a new ConsolidatedConfig instance and use for the contents.
   */
  private func createDefaultContents() {
    os_log(.info, log: log, "%d createDefaultContents", identity)
    self.restoreContents(ConsolidatedConfig(), save: true)
  }

  private func restoreContents(_ config: ConsolidatedConfig, save: Bool) {
    os_log(.info, log: log, "%d restoreContents", identity)
    self.contents = config
    if save {
      self.save(to: fileURL, for: .forCreating) { ok in
        os_log(.info, log: self.log, "%d restoreContents - save ok %d", self.identity, ok)
      }
    }
  }
}
