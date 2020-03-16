//
//  ScreenShots.swift
//  ScreenShots
// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class ScreenShots: XCTestCase {

    var app: XCUIApplication!
    var suffix: String!

    func snap(_ title: String) { snapshot(title + suffix) }

    func initialize(_ orientation: UIDeviceOrientation) {
        suffix = orientation.isPortrait ? "-Portrait" : "-Landscape"
        XCUIDevice.shared.orientation = orientation
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        let mainView = app.otherElements["MainView"]
        XCTAssert(mainView.waitForExistence(timeout: 5))
    }

    func switchViews() {
        let touchView = app.otherElements["TouchView"]
        touchView.doubleTap()
    }

    func showSoundFontsView() {
        let soundFontsView = app.otherElements["SoundFontsView"]
        guard !soundFontsView.exists else { return }
        switchViews()
        XCTAssert(soundFontsView.waitForExistence(timeout: 5))
    }

    func showFavoritesView() {
        let favoritesView = app.otherElements["FavoritesView"]
        guard !favoritesView.exists else { return }
        switchViews()
        XCTAssert(favoritesView.waitForExistence(timeout: 5))
    }

    func showSettingsView() {
        let settingsView = app.otherElements["SettingsView"]
        if app.buttons["More"].exists {
            app.buttons["More"].tap()
        }
        app.buttons["Settings"].tap()
        XCTAssert(settingsView.waitForExistence(timeout: 5))
    }

    func showFontEditView() {
        let musescoreStaticText = app.tables.staticTexts["MuseScore"]
        musescoreStaticText.tap()
        musescoreStaticText.swipeRight()
        app.tables.buttons["leading0"].tap()
    }

    func showFavoriteEditView() {
        let musescoreStaticText = app.tables.staticTexts["MuseScore"]
        musescoreStaticText.tap()
        app.scrollToTop()

        let tineElectricPianoText = app.tables.staticTexts["Tine Electric Piano"]
        XCTAssert(tineElectricPianoText.waitForExistence(timeout: 5))
        tineElectricPianoText.tap()

        let electricGrandStaticText = app.tables.staticTexts["Electric Grand"]
        if electricGrandStaticText.exists {
            electricGrandStaticText.swipeRight()
            let action = app.tables.buttons["leading0"]
            XCTAssert(action.waitForExistence(timeout: 5))
            action.tap()
        }

        let faveElectricGrandStaticText = app.tables.staticTexts["✪ Electric Grand"]
        faveElectricGrandStaticText.swipeRight()
        app.tables.buttons["leading0"].tap()

        let editView = app.otherElements["FavoriteEditor"]
        XCTAssert(editView.waitForExistence(timeout: 5))
    }

    func run(_ orientation: UIDeviceOrientation, _ title: String, setup: () -> Void) {
        initialize(orientation)
        setup()
        snap(title)
    }

    func testPatchesPortrait() { run(.portrait, "patches") { showSoundFontsView() } }
    func testPatchesLandscape() { run(.landscapeLeft, "patches") { showSoundFontsView() } }

    func testFavoritesPortrait() { run(.portrait, "favorites") { showFavoritesView() } }
    func testFavoritesLandscape() { run(.landscapeLeft, "favorites") { showFavoritesView() } }

    func testSettingsPortrait() { run(.portrait, "settings") { showSettingsView() } }
    func testSettingsLandscape() { run(.landscapeLeft, "settings") { showSettingsView() } }

    func testFontEditPortrait() { run(.portrait, "fontedit") { showFontEditView() } }
    func testFontEditLandscape() { run(.landscapeLeft, "fontedit") { showFontEditView() } }

    func testFavoriteEditPortrait() { run(.portrait, "favoriteedit") { showFavoriteEditView() } }
    func testFavoriteEditLandscape() { run(.landscapeLeft, "favoriteedit") { showFavoriteEditView() } }
}

extension XCUIApplication {
    private struct Constants {
        // Half way accross the screen and 10% from top
        static let topOffset = CGVector(dx: 0.5, dy: 0.1)

        // Half way accross the screen and 90% from top
        static let bottomOffset = CGVector(dx: 0.5, dy: 0.9)
    }

    var screenTopCoordinate: XCUICoordinate {
        windows.firstMatch.coordinate(withNormalizedOffset: Constants.topOffset)
    }

    var screenBottomCoordinate: XCUICoordinate {
        windows.firstMatch.coordinate(withNormalizedOffset: Constants.bottomOffset)
    }

    func scrollDownToElement(element: XCUIElement, maxScrolls: Int = 5) {
        for _ in 0..<maxScrolls {
            if element.exists && element.isHittable { element.scrollToTop(); break }
            scrollDown()
        }
    }

    func scrollDown() {
        screenBottomCoordinate.press(forDuration: 0.1, thenDragTo: screenTopCoordinate)
    }
}

extension XCUIElement {
    func scrollToTop() {
        let topCoordinate = XCUIApplication().screenTopCoordinate
        let elementCoordinate = coordinate(withNormalizedOffset: .zero)

        // Adjust coordinate so that the drag is straight up, otherwise
        // an embedded horizontal scrolling element will get scrolled instead
        let delta = topCoordinate.screenPoint.x - elementCoordinate.screenPoint.x
        let deltaVector = CGVector(dx: delta, dy: 0.0)

        elementCoordinate.withOffset(deltaVector).press(forDuration: 0.1, thenDragTo: topCoordinate)
    }
s}


