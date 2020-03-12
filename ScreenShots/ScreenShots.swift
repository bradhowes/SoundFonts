//
//  ScreenShots.swift
//  ScreenShots
// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class ScreenShots: XCTestCase {

    var app: XCUIApplication!

    func __testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        snapshot("01MainScreen")
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func __testTest() {
        let mainView = app.otherElements["MainView"]
        XCTAssert(mainView.waitForExistence(timeout: 5))

        let soundFontsView = app.otherElements["SoundFontsView"]
        XCTAssert(soundFontsView.exists)

        let favoritesView = app.otherElements["FavoritesView"]
        XCTAssert(!favoritesView.exists)

        let touchView = app.otherElements["TouchView"]
        XCTAssert(touchView.exists)

        touchView.doubleTap()
        XCTAssert(favoritesView.waitForExistence(timeout: 5))
    }

    func switchViews() {
        let touchView = app.otherElements["TouchView"]
        touchView.doubleTap()
    }

    func showSoundFontsView() {

        // Make sure that the SoundFontsView is visible
        let soundFontsView = app.otherElements["SoundFontsView"]
        guard !soundFontsView.exists else { return }
        switchViews()
        XCTAssert(soundFontsView.waitForExistence(timeout: 5))
    }

    func showFavoritesView() {

        // Make sure that the FavoritesView is visible
        let favoritesView = app.otherElements["FavoritesView"]
        guard !favoritesView.exists else { return }
        switchViews()
        XCTAssert(favoritesView.waitForExistence(timeout: 5))
    }

    func initialize(_ orientation: UIDeviceOrientation) {

        // Do this before creating the app
        XCUIDevice.shared.orientation = orientation
        continueAfterFailure = false

        // Create the app but wait until the MainView is visible
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        let mainView = app.otherElements["MainView"]
        XCTAssert(mainView.waitForExistence(timeout: 5))
    }

    func testPortrait() {
        initialize(.portrait)
        showSoundFontsView()
        snapshot("Patches-Portrait")
        showFavoritesView()
        snapshot("Favorites-Portrait")
    }

    func testLandscape() {
        initialize(.landscapeLeft)
        showSoundFontsView()
        snapshot("Patches-Landscape")
        showFavoritesView()
        snapshot("Favorites-Landscape")
    }
}
