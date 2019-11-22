// Copyright © 2018 Brad Howes. All rights reserved.
//
// NOTE: this uses some concepts found in the nice [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults)
// package. I did not have the need for the whole shebang so I just borrowed some of the functionality I found there.
//
// Here's their current Copyright notice taken from `Defauts.swift` file:

// SwiftyUserDefaults
//
// Copyright (c) 2015-2018 Radosław Pietruszewski, Łukasz Mróz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

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

extension String: SettingSerializable {
    
    public static func get(key: String, userDefaults: UserDefaults) -> String? {
        userDefaults.string(forKey: key)
    }
    
    public static func set(key: String, value: String, userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: key)
    }
}

extension Int: SettingSerializable {
    
    public static func get(key: String, userDefaults: UserDefaults) -> Int? {
        userDefaults.number(forKey: key)?.intValue
    }

    public static func set(key: String, value: Int, userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: key)
    }
}

extension Double: SettingSerializable {
    
    public static func get(key: String, userDefaults: UserDefaults) -> Double? {
        userDefaults.number(forKey: key)?.doubleValue
    }
    
    public static func set(key: String, value: Double, userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: key)
    }
}

extension Bool: SettingSerializable {
    
    public static func get(key: String, userDefaults: UserDefaults) -> Bool? {
        userDefaults.number(forKey: key)?.boolValue
    }

    public static func set(key: String, value: Bool, userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: key)
    }
}

extension Data: SettingSerializable {
    
    public static func get(key: String, userDefaults: UserDefaults) -> Data? {
        userDefaults.data(forKey: key)
    }
    
    public static func set(key: String, value: Data, userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: key)
    }
}

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
