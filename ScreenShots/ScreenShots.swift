// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
//import SoundFontsFramework

class ScreenShots: XCTestCase {
    let timeout = 5.0
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
        XCTAssert(mainView.waitForExistence(timeout: timeout))
    }

    func switchViews() {
        let touchView = app.otherElements["TouchView"]
        touchView.doubleTap()
    }

    func showSoundFontsView() {
        let soundFontsView = app.otherElements["SoundFontsView"]
        guard soundFontsView.exists == false else { return }
        switchViews()
        XCTAssert(soundFontsView.waitForExistence(timeout: timeout))
    }

    func testPatchesPortrait() { run(.portrait, "patches") { showSoundFontsView() } }
    func testPatchesLandscape() { run(.landscapeLeft, "patches") { showSoundFontsView() } }

    func showFavoritesView() {
        let favoritesView = app.otherElements["FavoritesView"]
        guard favoritesView.exists == false else { return }
        switchViews()
        XCTAssert(favoritesView.waitForExistence(timeout: timeout))
    }

    func testFavoritesPortrait() { run(.portrait, "favorites") { showFavoritesView() } }
    func testFavoritesLandscape() { run(.landscapeLeft, "favorites") { showFavoritesView() } }

    func showSettingsView() {
        let settingsView = app.otherElements["SettingsView"]
        if app.buttons["More Right"].exists {
            app.buttons["More Right"].tap()
        }
        app.buttons["Settings"].tap()
        XCTAssert(settingsView.waitForExistence(timeout: timeout))
    }

    func testSettingsPortrait() { run(.portrait, "settings") { showSettingsView() } }
    func testSettingsLandscape() { run(.landscapeLeft, "settings") { showSettingsView() } }

    func showFontEditView() {
        showSoundFontsView()
        let entry = app.tables.staticTexts["MuseScore"]
        entry.swipeRight()
        entry.swipeRight()
        app.tables.buttons["FontEditButton"].tap()
    }

    func testFontEditPortrait() { run(.portrait, "fontedit") { showFontEditView() } }
    func testFontEditLandscape() { run(.landscapeLeft, "fontedit") { showFontEditView() } }

    func showFavoriteEditView() {
        showSoundFontsView()
        let entry = app.tables.staticTexts["MuseScore"]
        entry.tap()
        app.scrollToTop()

        let preset1 = app.tables.staticTexts["Tine Electric Piano"]
        XCTAssert(preset1.waitForExistence(timeout: timeout))
        preset1.tap()

        let preset2 = app.tables.staticTexts["Electric Grand"]
        preset2.swipeRight()
        preset2.swipeRight()
        app.tables.buttons["EditSwipeAction"].tap()
    }

    func testFavoriteEditPortrait() { run(.portrait, "favoriteedit") { showFavoriteEditView() } }
    func testFavoriteEditLandscape() { run(.landscapeLeft, "favoriteedit") { showFavoriteEditView() } }

    func run(_ orientation: UIDeviceOrientation, _ title: String, setup: () -> Void) {
        initialize(orientation)
        setup()
        snap(title)
    }

    func testBlah() {
    }
}

extension XCUIApplication {
    private struct Constants {
        // Half way across the screen and 10% from top
        static let topOffset = CGVector(dx: 0.5, dy: 0.1)

        // Half way across the screen and 90% from top
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
}


