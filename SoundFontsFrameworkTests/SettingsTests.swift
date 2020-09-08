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

    static let settings = UserDefaults(suiteName: "com.braysoftware.SoundFonts.SharedSettings")!
    let Settings = SettingsManager(settings: settings)

    override func setUp() {
        Settings.remove(key: .intSetting)
        Settings.remove(key: .stringSetting)
        Settings.remove(key: .timeIntervalSetting)
        Settings.remove(key: .sharedIntSetting)
    }

    func testDefaults() {
        XCTAssertEqual(123, Settings[.intSetting])
        XCTAssertEqual("stringSetting", Settings[.stringSetting])

        // The default value should be pretty close to this
        let now = Date().timeIntervalSince1970
        let first = Settings[.timeIntervalSetting]
        XCTAssertEqual(now, first, accuracy: 0.01)

        Thread.sleep(forTimeInterval: 0.5)

        // The default value should be fixed to the first call of the default value generator
        let second = Settings[.timeIntervalSetting]
        XCTAssertEqual(first, second, accuracy: 0.0001)
    }

    func testSetting() {
        XCTAssertEqual(123, Settings[.intSetting])
        Settings[.intSetting] = 456
        XCTAssertEqual(456, Settings[.intSetting])

        XCTAssertEqual("stringSetting", Settings[.stringSetting])
        Settings[.stringSetting] = "blah"
        XCTAssertEqual("blah", Settings[.stringSetting])
    }

    func testMigration() {
        XCTAssertEqual(123, Settings[.sharedIntSetting])
        Self.settings.set(1000, forKey: SettingKeys.sharedIntSetting.userDefaultsKey)
        XCTAssertEqual(1000, Settings[.sharedIntSetting])
    }
}
