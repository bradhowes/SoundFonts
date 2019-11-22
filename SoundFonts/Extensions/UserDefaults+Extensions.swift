// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UserDefaults {

    func number(forKey key: String) -> NSNumber? { object(forKey: key) as? NSNumber }

    func hasKey<T>(_ key: SettingKey<T>) -> Bool { object(forKey: key.userDefaultsKey) != nil }

    func remove<T>(_ key: SettingKey<T>) { removeObject(forKey: key.userDefaultsKey) }

    /**
     Enable subscripting by SettingKey instances.

     - parameter key: SettingKey instance to use as a key into UserDefaults
     - returns: instance of the tempalte type from UserDefaults or the configured default value if it did not exist.
     */
    subscript<T: SettingSerializable>(key: SettingKey<T>) -> T {
        get { T.get(key: key.userDefaultsKey, userDefaults: self) ?? key.defaultValue }
        set { T.set(key: key.userDefaultsKey, value: newValue, userDefaults: self) }
    }
}
