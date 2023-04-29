// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFontsFramework

class AppTests: XCTestCase {

  private let app = XCUIApplication()

  override func setUp() {
    guard XCT_UI_TESTING_AVAILABLE != 0 else { return }

    #if !targetEnvironment(macCatalyst)
    XCUIDevice.shared.orientation = .portrait
    #endif

    super.setUp()
    app.launchArguments += ["-ui_testing"]
    app.launch()
  }

  /**
   - Launch the app
   - Bring up the setting panel
   - Make sure that the version shown in the Version label matches the value found in the bundle
   */
  func disabled_testVersionMatchesBundle() {
    guard XCT_UI_TESTING_AVAILABLE != 0 else { return }

    let mainView = app.otherElements["MainView"]
    XCTAssert(mainView.waitForExistence(timeout: 120))

    if app.buttons["More Right"].exists { app.buttons["More Right"].tap() }
    app.buttons["Settings"].tap()

    let settingsView = app.otherElements["SettingsView"]
    XCTAssert(settingsView.waitForExistence(timeout: 120))

    let version = settingsView.staticTexts["Version"]
    XCTAssert(version.waitForExistence(timeout: 120))

    let bundleBeingTested = Bundle(for: SettingsViewController.self)
    let releaseVersionNumber = bundleBeingTested.releaseVersionNumber

    XCTAssertEqual("v\(releaseVersionNumber)", version.label)
  }
}

//class AppPerfTest: XCTestCase {
//    func testApplicationLaunchTimeOnlyOnce() {
//        if #available(iOS 14.0, *) {
//            measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
//                XCUIApplication(bundleIdentifier: "com.braysoftware.SoundFonts").launch()
//            }
//        }
//    }
//}
