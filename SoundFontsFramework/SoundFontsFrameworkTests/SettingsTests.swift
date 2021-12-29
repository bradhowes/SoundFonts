// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

private let ud = UserDefaults(suiteName: "UserDefaultsTests")!

private struct TSettings {
  static let intSetting = SettingKey<Int>("intSetting", 123, source: ud)
  static let int32Setting = SettingKey<Int32>("int32Setting", -123, source: ud)
  static let doubleSetting = SettingKey<Double>("doubleSetting", 123.45, source: ud)
  static let floatSetting = SettingKey<Float>("floatSetting", -123.45, source: ud)
  static let stringSetting = SettingKey<String>("stringSetting", "stringSetting", source: ud)
  static let timeIntervalSetting = SettingKey<TimeInterval>("timeIntervalSetting", Date().timeIntervalSince1970, source: ud)
  static let boolSetting = SettingKey("boolSetting", false, source: ud)
  static let tagSetting = SettingKey("tagSetting", Tag.allTag.key, source: ud)
  static let lastPresetSetting = SettingKey<ActivePresetKind>("lastPresetSetting", .none, source: ud)
}

class SettingsTests: XCTestCase {

  override func setUp() {
    ud.remove(key: TSettings.intSetting)
    ud.remove(key: TSettings.stringSetting)
    ud.remove(key: TSettings.timeIntervalSetting)
    ud.remove(key: TSettings.doubleSetting)
    ud.remove(key: TSettings.floatSetting)
    ud.remove(key: TSettings.int32Setting)
    ud.remove(key: TSettings.boolSetting)
    ud.remove(key: TSettings.tagSetting)
  }

  func testDefaults() {
    XCTAssertEqual(123, ud[TSettings.intSetting])
    XCTAssertEqual(-123, ud[TSettings.int32Setting])
    XCTAssertEqual(123.45, ud[TSettings.doubleSetting], accuracy: 0.0001)
    XCTAssertEqual(-123.45, ud[TSettings.floatSetting], accuracy: 0.0001)
    XCTAssertEqual("stringSetting", ud[TSettings.stringSetting])

    let now = Date().timeIntervalSince1970
    let first = ud[TSettings.timeIntervalSetting]
    XCTAssertEqual(now, first, accuracy: 0.01)

    XCTAssertEqual(false, ud[TSettings.boolSetting])
    XCTAssertEqual(Tag.allTag.key, ud[TSettings.tagSetting])
  }

  func testSetting() {
    ud[TSettings.intSetting] = 456
    XCTAssertEqual(456, ud[TSettings.intSetting])

    ud[TSettings.int32Setting] = 398
    XCTAssertEqual(398, ud[TSettings.int32Setting])

    ud[TSettings.doubleSetting] = 456.987
    XCTAssertEqual(456.987, ud[TSettings.doubleSetting])

    ud[TSettings.floatSetting] = -456.987
    XCTAssertEqual(-456.987, ud[TSettings.floatSetting])

    XCTAssertEqual("stringSetting", ud[TSettings.stringSetting])
    ud[TSettings.stringSetting] = "blah"
    XCTAssertEqual("blah", ud[TSettings.stringSetting])

    ud[TSettings.boolSetting] = true
    XCTAssertEqual(true, ud[TSettings.boolSetting])

    ud[TSettings.tagSetting] = Tag.builtInTag.key
    XCTAssertEqual(Tag.builtInTag.key, ud[TSettings.tagSetting])
  }

  func testLegacyPatchSetting() {

    // Install old-school data into UserDefaults
    let base64 = "WzAseyJuYW1lIjoiQ2xhdmluZXQiLCJzb3VuZEZvbnRLZXkiOiI4NDFDN0FBQS1DQTg3LTRCNkUtQTI2Ny1FQUQzNzMwMDkwNEYiLCJwYXRjaEluZGV4Ijo3fV0="

    // Should be good here
    ud.set(Data(base64Encoded: base64)!, forKey: "lastPresetSetting")

    var value = ud[TSettings.lastPresetSetting]
    XCTAssertNotNil(value)
    XCTAssertEqual(7, value.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("841C7AAA-CA87-4B6E-A267-EAD37300904F", value.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Clavinet", value.soundFontAndPreset?.name)

    // Store new value
    ud[TSettings.lastPresetSetting] = ActivePresetKind.preset(
      soundFontAndPreset: .init(soundFontKey: UUID(uuidString: "841C7AAA-CA87-4B6E-A267-EAD37300904F")!,
                                presetIndex: 123, name: "Blah"))

    value = ud[TSettings.lastPresetSetting]
    XCTAssertNotNil(value)
    XCTAssertEqual(123, value.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("841C7AAA-CA87-4B6E-A267-EAD37300904F", value.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Blah", value.soundFontAndPreset?.name)

    // Raw-representation should be a dictionary
    let dict = ud.dictionary(forKey: "lastPresetSetting")
    XCTAssertNotNil(dict)
  }
}
