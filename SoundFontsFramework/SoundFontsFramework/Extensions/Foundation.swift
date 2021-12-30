// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

extension String: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}

extension Int: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}

extension Float: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}

extension Double: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}

extension Bool: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}

extension Data: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}

extension Date: SettingSerializable {
  public static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }
  public static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
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
