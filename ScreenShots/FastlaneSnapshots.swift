// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest

class FastlaneSnapshots: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func showSoundFontView() {
        let app = XCUIApplication()
        let e1: XCUIElementQuery = app.children(matching: .window)
        guard e1.count > 0 else { return }
        let e2 = e1.element(boundBy: 0)
        let e3 = e2.children(matching: .other).element
        let e4 = e3.children(matching: .other)
        guard e4.count > 1 else { return }
        let e5 = e4.element(boundBy: 1).children(matching: .other).element.children(matching: .collectionView)
        guard e5.count > 0 else { return }
        let e6 = e5.element
        e6.swipeRight()
    }

    func switchViews() {
        let app = XCUIApplication()
        let switcher = app.children(matching: .window)
            .element(boundBy: 0)
            .children(matching: .other)
            .element.children(matching: .other)
            .element(boundBy: 2)
            .children(matching: .other)
            .element.children(matching: .other)
            .element.children(matching: .other)
            .element
        switcher.doubleTap()
    }

    func testPortrait() {
        XCUIDevice.shared.orientation = .portrait
        showSoundFontView()
        snapshot("0FontsPortrait")
        switchViews()
        snapshot("0FavesPortrait")
    }

    func testLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        showSoundFontView()
        snapshot("0FontsLandscape")
        switchViews()
        snapshot("0FavesLandscape")
    }
}
