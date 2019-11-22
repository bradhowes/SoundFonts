// Copyright © 2018 Brad Howes. All rights reserved.
//
// NOTE: this uses some concepts found in the nice [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults)
// package. I did not have the need for the whole shebang so I just borrowed some of the functionality I found there.

import Foundation

/// Global variable to keep things concise.
let Settings = UserDefaults.standard

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

open class SettingKeys {
    fileprivate init() {}
}

/**
 Template class that supports get/set operations for the template type.
 */
open class SettingKey<ValueType: SettingSerializable>: SettingKeys {

    public let userDefaultsKey: String
    internal let defaultValue: ValueType

    public init(_ key: String, defaultValue: ValueType) {
        self.userDefaultsKey = key
        self.defaultValue = defaultValue
    }
}
