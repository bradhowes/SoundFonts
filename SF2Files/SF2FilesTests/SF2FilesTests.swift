// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SF2Files

class SF2FilesTests: XCTestCase {

    let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]

    func testResource() throws {
        for name in names {
            XCTAssertNoThrow(SF2Files.resource(name: name))
        }
    }

    func testAllResources() throws {
        let urls = SF2Files.allResources
        XCTAssertEqual(4, urls.count)
        for name in names {
            XCTAssertNotNil(urls.first { $0.lastPathComponent.hasPrefix(name) })
        }
    }
}
