// Copyright © 2018 Brad Howes. All rights reserved.
//
// NOTE: this uses some concepts found in the nice [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults)
// package. I did not have the need for the whole shebang so I just borrowed some of the functionality I found there.

import Foundation
import os

public class SettingsManager: NSObject {

    private let log = Logging.logger("SetMgr")
    private let appSettings = UserDefaults.standard

    public let sharedSettings = UserDefaults(suiteName: "group.com.braysoftware.SoundFontsShare")!

    public subscript<T: SettingSerializable>(key: SettingKey<T>) -> T {
        get {
            os_log(.info, log: log, "get '%s'", key.userDefaultsKey)
            if let value = T.get(key: key.userDefaultsKey, userDefaults: sharedSettings) {
                os_log(.info, log: log, "found in sharedSettings")
                return value
            }

            if let value = T.get(key: key.userDefaultsKey, userDefaults: appSettings) {
                os_log(.info, log: log, "found in appSettings -- copying to sharedSettings")
                sharedSettings[key] = value
                return value
            }

            os_log(.info, log: log, "not found -- using default value")
            return key.defaultValue
        }

        set {
            os_log(.info, log: log, "setting '%s'", key.userDefaultsKey)
            T.set(key: key.userDefaultsKey, value: newValue, userDefaults: sharedSettings)
            T.set(key: key.userDefaultsKey, value: newValue, userDefaults: appSettings)
        }
    }
}

//swiftlint:disable identifier_name
/// Global variable to keep things concise.
public let Settings = SettingsManager()
//swiftlint:enable identifier_name

/**
 Protocol for entities that can set a representation in UserDefaults
 */
public protocol SettingSettable {
    static func set(key: String, value: Self, userDefaults: UserDefaults)
}

/**
 Protocol for entities that can get a representation of from UserDefaults
 */
public protocol SettingGettable {
    static func get(key: String, userDefaults: UserDefaults) -> Self?
}

public typealias SettingSerializable = SettingSettable & SettingGettable

public class SettingKeys {
    fileprivate init() {}
}

/**
 Template class that supports get/set operations for the template type.
 */
public class SettingKey<ValueType: SettingSerializable>: SettingKeys {

    public let userDefaultsKey: String
    internal let defaultValue: ValueType

    public init(_ key: String, defaultValue: ValueType) {
        self.userDefaultsKey = key
        self.defaultValue = defaultValue
    }
}
