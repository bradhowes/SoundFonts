// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class Foundation_ExtensionsTests: XCTestCase {

    let userDefaults = UserDefaults(suiteName: "com.braysoftware.ignoreMe")!

    func testSettingSerializable() {
        String.set(key: "stringKey", value: "stringValue", userDefaults: userDefaults)
        XCTAssertEqual("stringValue", String.get(key: "stringKey", userDefaults: userDefaults))
    }

    func testIntSerializable() {
        Int.set(key: "intKey", value: 123, userDefaults: userDefaults)
        XCTAssertEqual(123, Int.get(key: "intKey", userDefaults: userDefaults))
    }

    func testFloatSerializable() {
        Float.set(key: "floatKey", value: 123.456, userDefaults: userDefaults)
        XCTAssertEqual(123.456, Float.get(key: "floatKey", userDefaults: userDefaults))
    }

    func testDoubleSerializable() {
        Double.set(key: "doubleKey", value: 123.456, userDefaults: userDefaults)
        XCTAssertEqual(123.456, Double.get(key: "doubleKey", userDefaults: userDefaults))
    }

    func testBoolSerializable() {
        Bool.set(key: "boolKey", value: true, userDefaults: userDefaults)
        XCTAssertEqual(true, Bool.get(key: "boolKey", userDefaults: userDefaults))
    }

    func testDateSerializable() {
        Date.set(key: "dateKey", value: Date(timeIntervalSince1970: 123123),
                 userDefaults: userDefaults)
        XCTAssertEqual(Date(timeIntervalSince1970: 123123), Date.get(key: "dateKey", userDefaults: userDefaults))
    }

    func testDoubleTimes() {
        XCTAssertEqual(1.day, 86400.seconds)
        XCTAssertEqual(5.minutes, 300.seconds)
        XCTAssertEqual(10.seconds, 10000.milliseconds)
        XCTAssertEqual(11.seconds, 11000.ms)
    }

//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
}
