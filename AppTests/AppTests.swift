//
//  AppTests.swift
//  AppTests
//
//  Created by Brad Howes on 3/16/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

import XCTest
@testable import SoundFontsFramework

class AppTests: XCTestCase {

    private let app = XCUIApplication()

    override func setUp() {
        XCUIDevice.shared.orientation = .portrait
        super.setUp()
        app.launchArguments += ["ui-testing"]
        app.launch()
    }

    func testVersionMatchesBundle() {
        let mainView = app.otherElements["MainView"]
        XCTAssert(mainView.waitForExistence(timeout: 5))

        if app.buttons["More Right"].exists { app.buttons["More Right"].tap() }
        app.buttons["Settings"].tap()

        let settingsView = app.otherElements["SettingsView"]
        XCTAssert(settingsView.waitForExistence(timeout: 5))

        let version = settingsView.staticTexts["Version"]
        XCTAssert(version.waitForExistence(timeout: 5))

        let bundleBeingTested = Bundle(for: SettingsViewController.self)
        let releaseVersionNumber = bundleBeingTested.releaseVersionNumber

        XCTAssertEqual("v\(releaseVersionNumber)", version.label)
    }
}
