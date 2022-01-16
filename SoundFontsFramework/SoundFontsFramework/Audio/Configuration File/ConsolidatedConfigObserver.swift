// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/**
 Watches for changes to the `config` value from a `ConsolidatedConfigProvider` instance.
 */
public struct ConsolidatedConfigObserver: Tasking {

  private let configProvider: ConsolidatedConfigProvider

  /// Convenience accessor for the collection of installed sound fonts
  public var soundFonts: SoundFontCollection {
    guard let config = configProvider.config else { fatalError("attempt to access nil config") }
    guard !config.soundFonts.isEmpty else { fatalError("encountered empty soundFonts collection")}
    return config.soundFonts
  }

  /// Convenience accessor for the collection of user favorites
  public var favorites: FavoriteCollection {
    guard let config = configProvider.config else { fatalError("attempt to access nil config") }
    return config.favorites
  }

  /// Convenience accessor for the collection of user tags for font filtering
  public var tags: TagCollection {
    guard let config = configProvider.config else { fatalError("attempt to access nil config") }
    return config.tags
  }

  /// True if a configuration has been loaded.
  public var isRestored: Bool { configProvider.config != nil }

  private var configProviderObserver: NSKeyValueObservation?

  /**
   Create a new observer.

   - parameter configProvider: the configuration file to observe
   - parameter restored: the closure to invoke when the file has been restored
   */
  public init(configProvider: ConsolidatedConfigProvider, restored closure: @escaping () -> Void) {
    self.configProvider = configProvider
    self.configProviderObserver = configProvider.observe(\.config) { _, _ in Self.onMain { closure() } }

    // Handle race where `config` is already loaded
    if isRestored {
      Self.onMain {
        closure()
      }
    }
  }

  /**
   Flag the configuration file as having a change that needs to be saved.
   */
  public func markAsChanged() {
    AskForReview.maybe()
    configProvider.markAsChanged()
  }
}
