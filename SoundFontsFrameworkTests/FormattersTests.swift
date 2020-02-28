// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class FormattersTests: XCTestCase {

    func testPatches() {
        XCTAssertEqual("no patches", Formatters.formatted(patchCount: 0))
        XCTAssertEqual("1 patch", Formatters.formatted(patchCount: 1))
        XCTAssertEqual("200 patches", Formatters.formatted(patchCount: 200))
    }

    func testFavorites() {
        XCTAssertEqual("no favorites", Formatters.formatted(favoriteCount: 0))
        XCTAssertEqual("1 favorite", Formatters.formatted(favoriteCount: 1))
        XCTAssertEqual("200 favorites", Formatters.formatted(favoriteCount: 200))
    }
}
