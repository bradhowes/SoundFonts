// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// Protocol for types that can store a value in UserDefaults
public protocol SettingSerializable {

  /**
   Register a default value for a setting key.

   - parameter key: the key to register under
   - parameter value: the value to register
   - parameter source: the container to register with
   */
  static func register(key: String, value: Self, source: UserDefaults)

  /**
   Obtain the setting value under the given key.

   - parameter key: the setting name
   - parameter source: the container to fetch from
   - returns: optional value
   */
  static func get(key: String, source: UserDefaults) -> Self
  /**
   Store a setting value under the given key.

   - parameter key: the setting name
   - parameter value: the value to store
   - parameter source: the container to store in
   */
  static func set(key: String, value: Self, source: UserDefaults)
}

extension SettingSerializable {

  /**
   Default registration implementation.

   - parameter key: the key to register under
   - parameter value: the value to register
   - parameter userDefaults: the UserDefaults instance to register in
   */
  public static func register(key: String, value: Self, source: UserDefaults) {
    source.register(defaults: [key: value])
  }
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

  /**
   Define a new setting key.

   - parameter key: the unique identifier to use for this setting
   - parameter defaultValue: the constant default value to use
   - parameter source: the setting container to register with
   */
  public init(_ key: String, _ defaultValue: ValueType, source: UserDefaults = .standard) {
    self.key = key
    ValueType.register(key: key, value: defaultValue, source: source)
  }

  /**
   Obtain a setting value.

   - parameter source: the setting container to query
   - returns: the current setting value
   */
  public func get(_ source: UserDefaults) -> ValueType {
    ValueType.get(key: key, source: source)
  }

  /**
   Set a setting value.

   - parameter source: the setting container to modify
   - parameter value: the new setting value
   */
  public func set(_ source: UserDefaults, _ value: ValueType) {
    ValueType.set(key: key, value: value, source: source)
  }
}
