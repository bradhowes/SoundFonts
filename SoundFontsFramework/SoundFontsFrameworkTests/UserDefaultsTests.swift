// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

extension SettingKeys {
  static let number = SettingKey<Int>("UserDefaultsTestIntSetting", defaultValue: 0)
}

class UserDefaultsTests: XCTestCase {

  let ud = UserDefaults(suiteName: "UserDefaultsTests")!

  override func setUp() {
    ud.removeObject(forKey: SettingKeys.number.userDefaultsKey)
  }

  func testNSNumberQueries() {
    let key = SettingKeys.number.userDefaultsKey
    ud.set(1.2345, forKey: key)
    var value = ud.number(forKey: key)
    XCTAssertNotNil(value)
    XCTAssertEqual(value!.doubleValue, 1.2345, accuracy: 0.0001)

    ud.set(98765, forKey: key)
    value = ud.number(forKey: key)
    XCTAssertNotNil(value)
    XCTAssertEqual(value!.intValue, 98765)
  }

  func testHasKey() {
    XCTAssertEqual(ud.hasKey(SettingKeys.number), false)
    ud.set(1, forKey: SettingKeys.number.userDefaultsKey)
    XCTAssertEqual(ud.hasKey(SettingKeys.number), true)
  }
}
