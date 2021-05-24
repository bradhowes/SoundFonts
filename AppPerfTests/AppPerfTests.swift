// Copyright © 2021 Brad Howes. All rights reserved.

import XCTest

@available(OSX 10.15, iOS 13.0, *)
class AppPerfTest: XCTestCase {
    func testApplicationLaunchTimeOnlyOnce() {
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            XCUIApplication(bundleIdentifier: "com.braysoftware.SoundFonts").launch()
        }
    }
}
