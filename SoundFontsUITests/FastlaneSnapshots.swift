//
//  FastlaneSnapshots.swift
//  SoundFontsUITests
//
//  Created by Brad Howes on 2/17/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

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

    func testExample() {
        snapshot("0Launch")
    }
}
