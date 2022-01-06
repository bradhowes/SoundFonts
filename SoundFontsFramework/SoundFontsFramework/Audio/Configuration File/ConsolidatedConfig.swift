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
