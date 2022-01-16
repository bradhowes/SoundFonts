// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/**
 Holds reference to ConsolidatedConfigFile and monitors it for changes to its `restored` attribute. When it changes
 to true, calls the closure which was given during construction. This facility is use by the various data owners to
 determine when there is data available for them to use.
 */
public final class ConsolidatedConfigFileObserver: Tasking {
  private let configFile: ConsolidatedConfigFile

  /// Convenience accessor for the collection of installed sound fonts
  public var soundFonts: SoundFontCollection {
    guard let config = configFile.config else { fatalError("attempt to access nil config") }
    guard !config.soundFonts.isEmpty else { fatalError("encountered empty soundFonts collection")}
    return config.soundFonts
  }

  /// Convenience accessor for the collection of user favorites
  public var favorites: FavoriteCollection {
    guard let config = configFile.config else { fatalError("attempt to access nil config") }
    return config.favorites
  }

  /// Convenience accessor for the collection of user tags for font filtering
  public var tags: TagCollection {
    guard let config = configFile.config else { fatalError("attempt to access nil config") }
    return config.tags
  }

  public var isRestored: Bool { configFile.config != nil }

  private var configFileObserver: NSKeyValueObservation?

  /**
   Create a new observer.

   - parameter configFile: the configuration file to observe
   - parameter restored: the closure to invoke when the file has been restored
   */
  public init(configFile: ConsolidatedConfigFile, restored closure: @escaping () -> Void) {
    self.configFile = configFile
    self.configFileObserver = configFile.observe(\.config) { _, _ in Self.onMain { closure() } }
  }

  /**
   Flag the configuration file as having a change that needs to be saved.
   */
  public func markAsChanged() {
    AskForReview.maybe()
    configFile.markAsChanged()
  }
}
