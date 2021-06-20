// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UserDefaults {

  /**
   Obtain an NSNumber value from UserDefaults

   - parameter key: the name of the setting to return
   - returns: optional NSNumber instance holding the value
   */
  public func number(forKey key: String) -> NSNumber? { object(forKey: key) as? NSNumber }

  /**
   Determine if UserDefaults contains a key under the given name

   - parameter key: the SettingKey to look for
   - returns: true if found
   */
  public func hasKey<T>(_ key: SettingKey<T>) -> Bool where T: SettingSerializable {
    object(forKey: key.userDefaultsKey) != nil
  }

  /**
   Remove the setting from UserDefaults

   - parameter key: the SettingKey to remove
   */
  public func remove<T>(key: SettingKey<T>) where T: SettingSerializable {
    removeObject(forKey: key.userDefaultsKey)
  }

  /**
   Enable subscripting by SettingKey instances.

   - parameter key: SettingKey instance to use as a key into UserDefaults
   - returns: instance of the template type from UserDefaults or the configured default value if it did not exist.
   */
  public subscript<T>(key: SettingKey<T>) -> T where T: SettingSerializable {
    get { T.get(key: key.userDefaultsKey, userDefaults: self) ?? key.defaultValue }
    set { T.set(key: key.userDefaultsKey, value: newValue, userDefaults: self) }
  }
}
