// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// Protocol for types that can store a value in UserDefaults
public protocol SettingSerializable {

  /**
   Obtain the setting value under the given key.

   - parameter key: the setting name
   - parameter source: the container to fetch from
   - returns: optional value
   */
  static func get(key: String, defaultValue: Self, source: Settings) -> Self

  /**
   Store a setting value under the given key.

   - parameter key: the setting name
   - parameter value: the value to store
   - parameter source: the container to store in
   */
  static func set(key: String, value: Self, source: Settings)
}

/// Container to place SettingKey definitions (as class members)
public class SettingKeys {

  /// Initialization of instance.
  fileprivate init() {}
}

/// Template class that supports get/set operations for the template type. Derive from SettingKeys to allow a SettingKey
/// to be found during auto-complete when used as a UserDefaults index.
public class SettingKey<ValueType: SettingSerializable>: SettingKeys {

  /// The unique identifier for this setting key
  public let key: String
  public let defaultValue: ValueType

  /**
   Define a new setting key.

   - parameter key: the unique identifier to use for this setting
   - parameter defaultValue: the constant default value to use
   */
  public init(_ key: String, _ defaultValue: ValueType) {
    self.key = key
    self.defaultValue = defaultValue
    super.init()
  }

  /**
   Obtain a setting value.

   - parameter source: the setting container to query
   - returns: the current setting value
   */
  @inlinable
  public func get(_ source: Settings) -> ValueType { ValueType.get(key: key, defaultValue: defaultValue, source: source) }

  /**
   Set a setting value.

   - parameter source: the setting container to modify
   - parameter value: the new setting value
   */
  @inlinable
  public func set(_ source: Settings, _ value: ValueType) { ValueType.set(key: key, value: value, source: source) }
}
