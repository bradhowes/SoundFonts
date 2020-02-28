// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

extension SettingKeys {
    static let favoritesChanged = SettingKey<String>("favoritesChanged", defaultValue: "")
    static let soundFontsChanged = SettingKey<String>("soundFontsChanged", defaultValue: "")
}

/**
 Monitors the settings that are shared between the SoundFonts application and the AUv3 app extension.
 */
final public class SharedStateMonitor: NSObject {
    private let log = Logging.logger("SSMon")

    /**
     Identifier of the entity that has made a change.
     */
    public enum StateChanger: Int {
        case application = 1
        case audioUnit = 2

        // Create a String value that will always be unique
        var uniqueString: String { "\(self.rawValue) \(Date().timeIntervalSince1970)" }
    }

    /**
     Identifier of the entity that changed
     */
    public enum StateChange {
        case favorites
        case soundFonts
    }

    private var myContext = 0
    private let changer: StateChanger

    /// Delegate that receives notifications when the shared state changes.
    public var block: ((StateChange)->Void)?

    /**
     Construct a new monitor for the given changer. Monitors the UserDefaults values for the favoritesChanged and
     soundFontsChanged keys.

     - parameter changer: the idenfier of the entity creating the monitor
     */
    public init(changer: StateChanger) {
        self.changer = changer
        super.init()
        Settings.sharedSettings.addObserver(self, forKeyPath: SettingKeys.favoritesChanged.userDefaultsKey,
                                            options: .new, context: &myContext)
        Settings.sharedSettings.addObserver(self, forKeyPath: SettingKeys.soundFontsChanged.userDefaultsKey,
                                            options: .new, context: &myContext)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard context == &myContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        // A usable value is "N TTT..." where N is either 1 or 2 and TTT... is a timestamp.
        guard let keyPath = keyPath,
            let rawValue = Settings.sharedSettings.string(forKey: keyPath),
            let tmp = Int(rawValue.split(separator: " ")[0]),
            let changer = StateChanger(rawValue: tmp),
            changer != self.changer else {
                return
        }

        switch keyPath {
        case SettingKeys.favoritesChanged.userDefaultsKey: block?(.favorites)
        case SettingKeys.soundFontsChanged.userDefaultsKey: block?(.soundFonts)
        default: break
        }
    }

    /**
     Notify the other entity that the Favorite collection has changed.
     */
    public func notifyFavoritesChanged() {
        Settings[.favoritesChanged] = changer.uniqueString
    }

    /**
     Notify the other entity that the SoundFont collection has changed.
     */
    public func notifySoundFontsChanged() {
        Settings[.soundFontsChanged] = changer.uniqueString
    }
}
