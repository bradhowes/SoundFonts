// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

private let settings = Settings(inApp: true, suiteName: "UserDefaultsTests")

private struct TSettings {
  static let intSetting = SettingKey<Int>("intSetting", 123)
  static let doubleSetting = SettingKey<Double>("doubleSetting", 123.45)
  static let floatSetting = SettingKey<Float>("floatSetting", -123.45)
  static let stringSetting = SettingKey<String>("stringSetting", "stringSetting")
  static let timeIntervalSetting = SettingKey<TimeInterval>("timeIntervalSetting", Date().timeIntervalSince1970)
  static let boolSetting = SettingKey("boolSetting", false)
  static let tagSetting = SettingKey("tagSetting", Tag.allTag.key)
  static let lastPresetSetting = SettingKey<ActivePresetKind>("lastPresetSetting", .none)
}

class SettingsTests: XCTestCase {

  override func setUp() {
    settings.remove(key: TSettings.intSetting)
    settings.remove(key: TSettings.stringSetting)
    settings.remove(key: TSettings.timeIntervalSetting)
    settings.remove(key: TSettings.doubleSetting)
    settings.remove(key: TSettings.floatSetting)
    settings.remove(key: TSettings.boolSetting)
    settings.remove(key: TSettings.tagSetting)
  }

  func testDefaults() {
    XCTAssertEqual(123, settings[TSettings.intSetting])
    XCTAssertEqual(123.45, settings[TSettings.doubleSetting], accuracy: 0.0001)
    XCTAssertEqual(-123.45, settings[TSettings.floatSetting], accuracy: 0.0001)
    XCTAssertEqual("stringSetting", settings[TSettings.stringSetting])

    let now = Date().timeIntervalSince1970
    let first = settings[TSettings.timeIntervalSetting]
    XCTAssertEqual(now, first, accuracy: 0.01)

    XCTAssertEqual(false, settings[TSettings.boolSetting])
    XCTAssertEqual(Tag.allTag.key, settings[TSettings.tagSetting])
  }

  func testSetting() {
    settings[TSettings.intSetting] = 456
    XCTAssertEqual(456, settings[TSettings.intSetting])

    settings[TSettings.doubleSetting] = 456.987
    XCTAssertEqual(456.987, settings[TSettings.doubleSetting])

    settings[TSettings.floatSetting] = -456.987
    XCTAssertEqual(-456.987, settings[TSettings.floatSetting])

    XCTAssertEqual("stringSetting", settings[TSettings.stringSetting])
    settings[TSettings.stringSetting] = "blah"
    XCTAssertEqual("blah", settings[TSettings.stringSetting])

    settings[TSettings.boolSetting] = true
    XCTAssertEqual(true, settings[TSettings.boolSetting])

    settings[TSettings.tagSetting] = Tag.builtInTag.key
    XCTAssertEqual(Tag.builtInTag.key, settings[TSettings.tagSetting])
  }

  func testLegacyPatchSetting() {

    // Install old-school data into UserDefaults
    let base64 = "WzAseyJuYW1lIjoiQ2xhdmluZXQiLCJzb3VuZEZvbnRLZXkiOiI4NDFDN0FBQS1DQTg3LTRCNkUtQTI2Ny1FQUQzNzMwMDkwNEYiLCJwYXRjaEluZGV4Ijo3fV0="

    // Should be good here
    settings.set(key: "lastPresetSetting", value: Data(base64Encoded: base64)!)

    var value = settings[TSettings.lastPresetSetting]
    XCTAssertNotNil(value)
    XCTAssertEqual(7, value.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("841C7AAA-CA87-4B6E-A267-EAD37300904F", value.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Clavinet", value.soundFontAndPreset?.name)

    // Store new value
    settings[TSettings.lastPresetSetting] = ActivePresetKind.preset(
      soundFontAndPreset: .init(soundFontKey: UUID(uuidString: "841C7AAA-CA87-4B6E-A267-EAD37300904F")!,
                                presetIndex: 123, name: "Blah"))

    value = settings[TSettings.lastPresetSetting]
    XCTAssertNotNil(value)
    XCTAssertEqual(123, value.soundFontAndPreset?.presetIndex)
    XCTAssertEqual("841C7AAA-CA87-4B6E-A267-EAD37300904F", value.soundFontAndPreset?.soundFontKey.uuidString)
    XCTAssertEqual("Blah", value.soundFontAndPreset?.name)

    // Raw-representation should be a dictionary
    let dict = settings.storage.dictionary(forKey: "lastPresetSetting")
    XCTAssertNotNil(dict)
  }
}
