// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

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

extension Date: SettingSerializable {

    public static func get(key: String, userDefaults: UserDefaults) -> Date? {
        userDefaults.object(forKey: key) as? Date
    }

    public static func set(key: String, value: Date, userDefaults: UserDefaults) {
        userDefaults.set(value, forKey: key)
    }
}

extension Double {
    public var milliseconds: TimeInterval { self / 1000 }
    public var millisecond: TimeInterval { milliseconds }
    public var ms: TimeInterval { milliseconds }

    public var seconds: TimeInterval { self }
    public var second: TimeInterval { seconds }

    public var minutes: TimeInterval { seconds * 60 }
    public var minute: TimeInterval { minutes }

    public var hours: TimeInterval { minutes * 60 }
    public var hour: TimeInterval { hours }

    public var days: TimeInterval { hours * 24 }
    public var day: TimeInterval { days }
}
