// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

private let ud = UserDefaults(suiteName: "UserDefaultsTests")!

private struct Settings {
  static let intSetting = SettingKey<Int>("intSetting", 123, userDefaults: ud)
  static let int32Setting = SettingKey<Int32>("int32Setting", -123, userDefaults: ud)
  static let doubleSetting = SettingKey<Double>("doubleSetting", 123.45, userDefaults: ud)
  static let floatSetting = SettingKey<Float>("floatSetting", -123.45, userDefaults: ud)
  static let stringSetting = SettingKey<String>("stringSetting", "stringSetting", userDefaults: ud)
  static let timeIntervalSetting = SettingKey<TimeInterval>("timeIntervalSetting", Date().timeIntervalSince1970, userDefaults: ud)
  static let boolSetting = SettingKey("boolSetting", false, userDefaults: ud)
  static let tagSetting = SettingKey("tagSetting", Tag.allTag.key, userDefaults: ud)
}

class SettingsTests: XCTestCase {

  override func setUp() {
    ud.remove(key: Settings.intSetting)
    ud.remove(key: Settings.stringSetting)
    ud.remove(key: Settings.timeIntervalSetting)
    ud.remove(key: Settings.doubleSetting)
    ud.remove(key: Settings.floatSetting)
    ud.remove(key: Settings.int32Setting)
    ud.remove(key: Settings.boolSetting)
    ud.remove(key: Settings.tagSetting)
  }

  func testDefaults() {
    XCTAssertEqual(123, ud[Settings.intSetting])
    XCTAssertEqual(-123, ud[Settings.int32Setting])
    XCTAssertEqual(123.45, ud[Settings.doubleSetting], accuracy: 0.0001)
    XCTAssertEqual(-123.45, ud[Settings.floatSetting], accuracy: 0.0001)
    XCTAssertEqual("stringSetting", ud[Settings.stringSetting])

    let now = Date().timeIntervalSince1970
    let first = ud[Settings.timeIntervalSetting]
    XCTAssertEqual(now, first, accuracy: 0.01)

    XCTAssertEqual(false, ud[Settings.boolSetting])
    XCTAssertEqual(Tag.allTag.key, ud[Settings.tagSetting])
  }

  func testSetting() {
    ud[Settings.intSetting] = 456
    XCTAssertEqual(456, ud[Settings.intSetting])

    ud[Settings.int32Setting] = 398
    XCTAssertEqual(398, ud[Settings.int32Setting])

    ud[Settings.doubleSetting] = 456.987
    XCTAssertEqual(456.987, ud[Settings.doubleSetting])

    ud[Settings.floatSetting] = -456.987
    XCTAssertEqual(-456.987, ud[Settings.floatSetting])

    XCTAssertEqual("stringSetting", ud[Settings.stringSetting])
    ud[Settings.stringSetting] = "blah"
    XCTAssertEqual("blah", ud[Settings.stringSetting])

    ud[Settings.boolSetting] = true
    XCTAssertEqual(true, ud[Settings.boolSetting])

    ud[Settings.tagSetting] = Tag.builtInTag.key
    XCTAssertEqual(Tag.builtInTag.key, ud[Settings.tagSetting])
  }
}
