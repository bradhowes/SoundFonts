// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os.log

/**
 Originally, the SoundFonts app loaded three separate config files. However, there was risk of data corruption if the
 files were not updated all at once. This was made worse with the AUv3 component, since it and the app shared the same
 configuration files. This consolidated version stores everything in one file, so the risk of corruption is reduced.
 Further, it relies on UIDocument which provides a safe and reliable means of making changes and writing them to disk
 even if there are two or more parties doing it. For our case, we just let the last one win without notifying the user
 that there was even a conflict.
 */
public class ConsolidatedConfig: NSObject, Codable {
  private static let log: Logger = Logging.logger("ConsolidatedConfig")
  private var log: Logger { Self.log }

  /// The collection of installed soundfonts and their presets
  public var soundFonts: SoundFontCollection
  /// The collection of created favorites
  public var favorites: FavoriteCollection
  /// The collection of tags that categorize the soundfonts
  public var tags: TagCollection

  /**
   New instance

   - parameter soundFonts: the collection of soundfonts to store in the configuration
   - parameter favorites: the collection of favorites to store in the configuration
   - parameter tags: the collection of tags to store in the configuration
   */
  public init(soundFonts: SoundFontCollection, favorites: FavoriteCollection, tags: TagCollection) {
    self.soundFonts = soundFonts
    self.favorites = favorites
    self.tags = tags
    super.init()
  }

  /// Construct a new default collection, such as when the app is first installed or there is a problem loading a
  /// previously-saved file.
  override public init() {
    soundFonts = SoundFontsManager.defaultCollection
    favorites = FavoritesManager.defaultCollection
    tags = TagsManager.defaultCollection
    super.init()
    log.debug("creating default collection")
  }
}

extension ConsolidatedConfig {

  /// Custom description for the instance
  override public var description: String { "<Config \(soundFonts), \(favorites), \(tags)>" }
}

extension Encodable {
  func encoded() throws -> Data { try PropertyListEncoder().encode(self) }
}

extension Data {
  func decoded<T: Decodable>() throws -> T { try PropertyListDecoder().decode(T.self, from: self) }
}
