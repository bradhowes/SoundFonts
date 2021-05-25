// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

extension SettingKeys {
    static let intSetting = SettingKey<Int>("intSetting", defaultValue: 123)
    static let stringSetting = SettingKey<String>("stringSetting", defaultValueGenerator: { "stringSetting" })
    static let timeIntervalSetting = SettingKey<TimeInterval>("timeIntervalSetting", defaultValueGenerator: { Date().timeIntervalSince1970 })
    static let sharedIntSetting = SettingKey<Int>("sharedIntSetting", defaultValue: 123)
}

class SettingsTests: XCTestCase {

    let settings = UserDefaults(suiteName: "com.braysoftware.SoundFonts.SharedSettings")!

    override func setUp() {
        settings.remove(key: .intSetting)
        settings.remove(key: .stringSetting)
        settings.remove(key: .timeIntervalSetting)
        settings.remove(key: .sharedIntSetting)
    }

    func testDefaults() {
        XCTAssertEqual(123, settings[.intSetting])
        XCTAssertEqual("stringSetting", settings[.stringSetting])

        // The default value should be pretty close to this
        let now = Date().timeIntervalSince1970
        let first = settings[.timeIntervalSetting]
        XCTAssertEqual(now, first, accuracy: 0.01)

        Thread.sleep(forTimeInterval: 0.5)

        // The default value should be fixed to the first call of the default value generator
        let second = settings[.timeIntervalSetting]
        XCTAssertEqual(first, second, accuracy: 0.0001)
    }

    func testSetting() {
        XCTAssertEqual(123, settings[.intSetting])
        settings[.intSetting] = 456
        XCTAssertEqual(456, settings[.intSetting])

        XCTAssertEqual("stringSetting", settings[.stringSetting])
        settings[.stringSetting] = "blah"
        XCTAssertEqual("blah", settings[.stringSetting])
    }

    func testMigration() {
        XCTAssertEqual(123, settings[.sharedIntSetting])
        settings.set(1000, forKey: SettingKeys.sharedIntSetting.userDefaultsKey)
        XCTAssertEqual(1000, settings[.sharedIntSetting])
    }
}
