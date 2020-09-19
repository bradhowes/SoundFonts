// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

//swiftlint:disable identifier_name
/// Global variable to keep things concise.
public let settings = UserDefaults(suiteName: "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare") ?? UserDefaults.standard
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
 Template class that supports get/set operations for the template type.
 */
public class SettingKey<ValueType: SettingSerializable> {
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

    /// The default value to use when the setting has not yet been set. We defer the setting of in case it is from a
    /// generator and the initial value must come from runtime code.
    public lazy var defaultValue: ValueType = self._defaultValue.defaultValue

    /**
     Define a new setting key.

     - parameter key: the unique identifier to use for this setting
     - parameter defaultValue: the constant default value to use
     */
    public init(_ key: String, defaultValue: ValueType) {
        self.userDefaultsKey = key
        self._defaultValue = .constant(defaultValue)
    }

    /**
     Define a new setting key.

     - parameter key: the unique identifier to use for this setting
     - parameter defaultValueGenerator: block to call to generate the default value, with a guarantee that this will
     only be called at most one time.
     */
    public init(_ key: String, defaultValueGenerator: @escaping ()->ValueType) {
        self.userDefaultsKey = key
        self._defaultValue = .generator(defaultValueGenerator)
    }
}
