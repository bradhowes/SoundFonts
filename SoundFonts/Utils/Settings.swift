// Copyright © 2018 Brad Howes. All rights reserved.
//
// NOTE: this uses some concepts found in the nice [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults)
// package. I did not have the need for the whole shebang so I just borrowed some of the functionality I found there.

import Foundation

//swiftlint:disable identifier_name
/// Global variable to keep things concise.
let Settings = UserDefaults.standard
//swiftlint:enable identifier_name

/**
 Protocol for entities that can set a representation in UserDefaults
 */
protocol SettingSettable {
    static func set(key: String, value: Self, userDefaults: UserDefaults)
}

/**
 Protocol for entities that can get a representation of from UserDefaults
 */
protocol SettingGettable {
    static func get(key: String, userDefaults: UserDefaults) -> Self?
}

typealias SettingSerializable = SettingSettable & SettingGettable

class SettingKeys {
    fileprivate init() {}
}

/**
 Template class that supports get/set operations for the template type.
 */
class SettingKey<ValueType: SettingSerializable>: SettingKeys {

    let userDefaultsKey: String
    internal let defaultValue: ValueType

    init(_ key: String, defaultValue: ValueType) {
        self.userDefaultsKey = key
        self.defaultValue = defaultValue
    }
}
