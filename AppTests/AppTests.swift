//
//  AppTests.swift
//  AppTests
//
//  Created by Brad Howes on 3/16/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

import XCTest
import SoundFontsFramework

class AppTests: XCTestCase {

    func testVersionMatchesBundle() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        let mainView = app.otherElements["MainView"]
        XCTAssert(mainView.waitForExistence(timeout: 5))

        if app.buttons["More"].exists { app.buttons["More"].tap() }
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

extension Bundle {

    private func string(forKey key: String) -> String { infoDictionary?[key] as? String ?? "" }

    var releaseVersionNumber: String { string(forKey: "CFBundleShortVersionString") }
    var buildVersionNumber: String { string(forKey: "CFBundleVersion") }
    var bundleID: String { Bundle.main.bundleIdentifier?.lowercased() ?? "" }
    var scheme: String {
        if bundleID.contains(".dev") { return " Dev" }
        if bundleID.contains(".staging") { return " Staging" }
        return ""
    }

    var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(scheme)" }
}
