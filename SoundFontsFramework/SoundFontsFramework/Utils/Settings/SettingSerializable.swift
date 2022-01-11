// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/**
 Protocol for types that can store a value in UserDefaults. Only types that UserDefaults supports should conform to
 this. Additional types should convert their values into fundamental types such as `Data` or `Dictionary<String, Any>`.
 */
public protocol SettingSerializable {

  /**
   Obtain the setting value under the given key.

   - parameter key: the setting name
   - parameter defaultValue: the default value to apply if the setting does not yet exist
   - parameter source: the container to fetch from
   - returns: value from the source
   */
  static func get(key: String, defaultValue: Self, source: Settings) -> Self

  /**
   Store a setting value under the given key.

   - parameter key: the setting name
   - parameter value: the value to save
   - parameter source: the container to save into
   */
  static func set(key: String, value: Self, source: Settings)
}

public extension SettingSerializable {

  /**
   Default implementation of `SettingSerializable.get`

   - parameter key: the setting name
   - parameter defaultValue: the default value to apply if the setting does not yet exist
   - parameter source: the container to fetch from
   - returns: value from the source
   */
  static func get(key: String, defaultValue: Self, source: Settings) -> Self {
    source.get(key: key, defaultValue: defaultValue)
  }

  /**
   Default implementation of `SettingSerializable.set`

   - parameter key: the setting name
   - parameter value: the value to save
   - parameter source: the container to save into
   */
  static func set(key: String, value: Self, source: Settings) {
    source.set(key: key, value: value)
  }
}
