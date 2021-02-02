// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/**
 Delay audio effect by way of Apple's AVAudioUnitDelay component.
 */
public final class ConfigFileObserver {
    public let configFile: ConsolidatedConfigFile
    public private(set) var restored = false

    public var soundFonts: LegacySoundFontCollection { configFile.config.soundFonts }
    public var favorites: LegacyFavoriteCollection { configFile.config.favorites }
    public var tags: LegacyTagCollection { configFile.config.tags }

    private var configFileObserver: NSKeyValueObservation?

    public init(configFile: ConsolidatedConfigFile, closure: @escaping () -> Void) {
        self.configFile = configFile
        self.configFileObserver = configFile.observe(\.restored) { _, _ in self.checkRestored(closure) }
        checkRestored(closure)
    }

    public func markChanged() {
        AskForReview.maybe()
        configFile.updateChangeCount(.done)
    }

    private func checkRestored(_ closure:() -> Void) {
        guard configFile.restored == true else { return }
        restored = true
        closure()
    }
}
