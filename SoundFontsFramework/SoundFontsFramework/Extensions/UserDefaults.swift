// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public extension UserDefaults {

  /**
   Remove the setting from UserDefaults

   - parameter key: the SettingKey to remove
   */
  @inlinable
  func remove<T>(key: SettingKey<T>) { removeObject(forKey: key.key) }
}
