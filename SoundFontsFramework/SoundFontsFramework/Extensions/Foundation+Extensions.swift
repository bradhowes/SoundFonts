// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

extension String: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> String {
    userDefaults.string(forKey: key)!
  }
  public static func set(key: String, value: String, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Int: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Int {
    // swiftlint:disable force_cast
    userDefaults.object(forKey: key) as! Int
    // swiftlint:enable force_cast
  }
  public static func set(key: String, value: Int, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Int32: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Int32 {
    // swiftlint:disable force_cast
    userDefaults.object(forKey: key) as! Int32
    // swiftlint:enable force_cast
  }
  public static func set(key: String, value: Int32, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Float: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Float {
    // swiftlint:disable force_cast
    userDefaults.object(forKey: key) as! Float
    // swiftlint:enable force_cast
  }
  public static func set(key: String, value: Float, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Double: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Double {
    // swiftlint:disable force_cast
    userDefaults.object(forKey: key) as! Double
    // swiftlint:enable force_cast
  }
  public static func set(key: String, value: Double, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Bool: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Bool {
    // swiftlint:disable force_cast
    userDefaults.object(forKey: key) as! Bool
    // swiftlint:enable force_cast
  }
  public static func set(key: String, value: Bool, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Data: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Data {
    userDefaults.data(forKey: key)!
  }
  public static func set(key: String, value: Data, userDefaults: UserDefaults) {
    userDefaults.set(value, forKey: key)
  }
}

extension Date: SettingSerializable {
  public static func get(key: String, userDefaults: UserDefaults) -> Date {
    // swiftlint:disable force_cast
    userDefaults.object(forKey: key) as! Date
    // swiftlint:enable force_cast
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

extension Float {

  /**
   Restrict a value to be between two others

   - parameter minValue: the lowest acceptable value
   - parameter maxValue: the highest acceptable value
   - returns: clamped value
   */
  public func clamp(min minValue: Self, max maxValue: Self) -> Self {
    min(max(self, minValue), maxValue)
  }
}

extension Double {

  /**
   Restrict a value to be between two others

   - parameter minValue: the lowest acceptable value
   - parameter maxValue: the highest acceptable value
   - returns: clamped value
   */
  public func clamp(min minValue: Self, max maxValue: Self) -> Self {
    min(max(self, minValue), maxValue)
  }
}
