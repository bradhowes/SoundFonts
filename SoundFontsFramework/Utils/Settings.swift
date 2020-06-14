// Copyright © 2018 Brad Howes. All rights reserved.
//
// NOTE: this uses some concepts found in the nice [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults)
// package. I did not have the need for the whole shebang so I just borrowed some of the functionality I found there.

import Foundation
import os

/**
 Manages access to user settings. Relies on UserDefaults for the actual storage. Originally, all settings were stored in
 the `standard` UserDefaults collection. However, with the introduction of the AUv3 extension, settings are now stored
 in a `shared` UserDefaults collection called "group.com.braysoftware.SoundFontsShare". To work with older app installs,
 the manager will fall back to `standard` collection if a setting does not exist in the `shared` collection.
 */
public class SettingsManager: NSObject {

    private let log = Logging.logger("SetMgr")

    private let appSettings: UserDefaults
    public let sharedSettings: UserDefaults!

    public init(shared: UserDefaults, app: UserDefaults) {
        self.sharedSettings = shared
        self.appSettings = app
    }

    public subscript<T: SettingSerializable>(key: SettingKey<T>) -> T {
        get {
            if key.shared {
                if let value = T.get(key: key.userDefaultsKey, userDefaults: sharedSettings) {
                    return value
                }
            }

            if let value = T.get(key: key.userDefaultsKey, userDefaults: appSettings) {
                if key.shared {
                    sharedSettings[key] = value
                }
                return value
            }

            return key.defaultValue
        }

        set {
            if key.shared {
                T.set(key: key.userDefaultsKey, value: newValue, userDefaults: sharedSettings)
            }
            T.set(key: key.userDefaultsKey, value: newValue, userDefaults: appSettings)
        }
    }

    public func remove<T>(key: SettingKey<T>) {
        appSettings.remove(key)
        sharedSettings.remove(key)
    }
}

//swiftlint:disable identifier_name
/// Global variable to keep things concise.
public let Settings = SettingsManager(shared: UserDefaults(suiteName: "group.com.braysoftware.SoundFontsShare")!,
                                      app: UserDefaults.standard)
//swiftlint:enable identifier_name

/**
 Protocol for types that can store a value in UserDefaults
 */
public protocol SettingSettable {

    /**
     Store a setting value under the given key.

     - parameter key: the setting name
     - parameter value: the value to store
     - parameter userDefaults: the container to store in
     */
    static func set(key: String, value: Self, userDefaults: UserDefaults)
}

/**
 Protocol for types that can fetch a value from UserDefaults
 */
public protocol SettingGettable {

    /**
     Obtain the setting value under the given key.

     - parameter key: the setting name
     - parameter userDefaults: the container to fetch from
     - returns: optional value
     */
    static func get(key: String, userDefaults: UserDefaults) -> Self?
}

public typealias SettingSerializable = SettingSettable & SettingGettable

/**
 A type to extend with SettingKey definitions
 */
public class SettingKeys {
    fileprivate init() {}
}

/**
 Template class that supports get/set operations for the template type.
 */
public class SettingKey<ValueType: SettingSerializable>: SettingKeys {
    typealias ValueType = ValueType

    /**
     There are two types of default values: a constant and a generator. The latter is useful when the value must be
     determined at runtime.
     */
    enum DefaultValue {
        case constant(ValueType)
        case generator(()->ValueType)

        /// Obtain an actual default value. NOTE: for a generator type, this may not be idempotent.
        var defaultValue: ValueType {
            switch self {
            case .constant(let value): return value
            case .generator(let value): return value()
            }
        }
    }

    private let _defaultValue: DefaultValue

    /// The unique identifier for this setting key
    public let userDefaultsKey: String

    /// If true, the setting is shared with others on the same devices
    public let shared: Bool

    /// The default value to use when the setting has not yet been set. We defer the setting of in case it is from a
    /// generator and the initial value must come from runtime code.
    public lazy var defaultValue: ValueType = self._defaultValue.defaultValue

    fileprivate var observers = [UUID : (ValueType)->Void]()

    /**
     Define a new setting key.

     - parameter key: the unique identifier to use for this setting
     - parameter defaultValue: the constant default value to use
     */
    public init(_ key: String, defaultValue: ValueType, shared: Bool = false) {
        self.userDefaultsKey = key
        self.shared = shared
        self._defaultValue = .constant(defaultValue)
    }

    /**
     Define a new setting key.

     - parameter key: the unique identifier to use for this setting
     - parameter defaultValueGenerator: block to call to generate the default value, with a guarantee that this will
     only be called at most one time.
     */
    public init(_ key: String, shared: Bool = false, defaultValueGenerator: @escaping ()->ValueType) {
        self.userDefaultsKey = key
        self.shared = shared
        self._defaultValue = .generator(defaultValueGenerator)
    }
}
