// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

private let ud = UserDefaults(suiteName: "UserDefaultsTests")!

private struct Settings {
  static let number = SettingKey<Int>("UserDefaultsTestIntSetting", 0, source: ud)
}

class UserDefaultsTests: XCTestCase {

  override func setUp() {
    ud.removeObject(forKey: Settings.number.key)
  }

  func testNSNumberQueries() {
    let key = Settings.number.key
    ud.set(11, forKey: key)
    var value = ud.object(forKey: key) as? Int
    XCTAssertNotNil(value)
    XCTAssertEqual(value, 11)

    ud.set(98765, forKey: key)
    value = ud.object(forKey: key) as? Int
    XCTAssertNotNil(value)
    XCTAssertEqual(value, 98765)
  }
}
