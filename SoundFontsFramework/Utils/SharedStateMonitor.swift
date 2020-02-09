// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

extension SettingKeys {
    static let favoritesChanged = SettingKey<Int>("favoritesChanged", defaultValue: -1)
    static let soundFontsChanged = SettingKey<Int>("soundFontsChanged", defaultValue: -1)
}

public enum SharedStateChanger: Int {
    case application = 1
    case audioUnit = 2
}

public protocol SharedStateMonitorDelegate: class {

    func favoritesChangedNotification()

    func soundFontsChangedNotification()
}

public class SharedStateMonitor: NSObject {
    private let log = Logging.logger("SSMon")

    private var myContext = 0
    private let changer: SharedStateChanger

    public weak var delegate: SharedStateMonitorDelegate?

    public init(changer: SharedStateChanger) {
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

        guard let keyPath = keyPath,
            let delegate = self.delegate,
            let changer = SharedStateChanger(rawValue: Settings.sharedSettings.integer(forKey: keyPath)),
            changer != self.changer else {
                return
        }

        switch keyPath {
        case SettingKeys.favoritesChanged.userDefaultsKey: delegate.favoritesChangedNotification()
        case SettingKeys.soundFontsChanged.userDefaultsKey: delegate.soundFontsChangedNotification()
        default: break
        }
    }

    public func notifyFavoritesChanged() {
        Settings[.favoritesChanged] = changer.rawValue
    }

    public func notifySoundFontsChanged() {
        Settings[.soundFontsChanged] = changer.rawValue
    }
}
