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

    func switchViews() {
        XCUIApplication().children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element.swipeLeft()
    }

    func testPortrait() {
        XCUIDevice.shared.orientation = .portrait
        snapshot("0FontsPortrait")
        switchViews()
        snapshot("0FavesPortrait")
        switchViews()
    }

    func testLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        snapshot("0FontsLandscape")
        switchViews()
        snapshot("0FavesLandscape")
        switchViews()
    }
}
