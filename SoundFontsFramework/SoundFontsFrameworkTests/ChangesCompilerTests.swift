// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFontsFramework

class ChangesCompilerTests: XCTestCase {

    func testRecent() {
        let found = ChangesCompiler.compile(since: "999999.4.5")
        XCTAssertEqual(found.count, 0)
    }

    func testPast() {
        let found = ChangesCompiler.compile(since: "2.18.3")
        XCTAssertEqual(found.count, 4)
    }
}
