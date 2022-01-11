// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/**
 Generic class that holds a definition of a given setting's name, type, and default value. Derived from SettingKeys to
 allow a SettingKey to be found during auto-complete when used as a Settings index.
 */
public class SettingKey<ValueType: SettingSerializable>: SettingKeys {

  /// The unique identifier for this setting key
  public let key: String

  /// The default value to register for the setting
  public let defaultValue: ValueType

  /**
   Define a new setting key.

   - parameter key: the unique identifier to use for this setting
   - parameter defaultValue: the constant default value to use
   */
  public init(_ key: String, _ defaultValue: ValueType) {
    self.key = key
    self.defaultValue = defaultValue
  }
}
