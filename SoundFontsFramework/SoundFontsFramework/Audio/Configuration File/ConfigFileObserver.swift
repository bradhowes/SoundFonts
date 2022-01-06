// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/**
 Holds reference to ConsolidatedConfigFile and monitors it for changes to its `restored` attribute. When it changes
 to true, calls the closure which was given during construction. This facility is use by the various data owners to
 determine when there is data available for them to use.
 */
public final class ConfigFileObserver {
  private let configFile: ConsolidatedConfigFile

  /// Flag indicating that the configuration file has been read in and the runtime elements reconstituted from it
  public private(set) var restored = false

  /// Convenience accessor for the collection of installed sound fonts
  public var soundFonts: SoundFontCollection {
    precondition(restored)
    return configFile.config.soundFonts
  }

  /// Convenience accessor for the collection of user favorites
  public var favorites: FavoriteCollection {
    precondition(restored)
    return configFile.config.favorites
  }

  /// Convenience accessor for the collection of user tags for font filtering
  public var tags: TagCollection {
    precondition(restored)
    return configFile.config.tags
  }

  private var configFileObserver: NSKeyValueObservation?

  /**
   Create a new observer.

   - parameter configFile: the configuration file to observe
   - parameter restored: the closure to invoke when the file has been restored
   */
  public init(configFile: ConsolidatedConfigFile, restored closure: @escaping () -> Void) {
    self.configFile = configFile
    self.configFileObserver = configFile.observe(\.restored) { [weak self] _, _ in
      self?.checkRestored(closure)
    }

    checkRestored(closure)
  }

  /**
   Flag the configuration file as having a change that needs to be saved.
   */
  public func markChanged() {
    AskForReview.maybe()
    configFile.updateChangeCount(.done)
  }
}

private extension ConfigFileObserver {

  func checkRestored(_ closure: () -> Void) {
    guard configFile.restored == true else { return }
    restored = true
    closure()
  }
}
