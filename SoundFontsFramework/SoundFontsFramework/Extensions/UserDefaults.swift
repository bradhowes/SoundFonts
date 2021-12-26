// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public extension UserDefaults {

  /**
   Remove the setting from UserDefaults

   - parameter key: the SettingKey to remove
   */
  @inlinable
  func remove<T>(key: SettingKey<T>) { removeObject(forKey: key.key) }

  /**
   Enable subscripting by SettingKey instances.

   - parameter key: SettingKey instance to use as a key into UserDefaults
   - returns: instance of the template type from UserDefaults
   */
  @inlinable
  subscript<T>(key: SettingKey<T>) -> T {
    get { key.get(self) }
    set { key.set(self, newValue) }
  }
}
