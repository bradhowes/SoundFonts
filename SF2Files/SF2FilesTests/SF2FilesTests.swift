// Copyright © 2020 Brad Howes. All rights reserved.

import SF2Files
import XCTest

class SF2FilesTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]

  func testValidation() throws {
    XCTAssertNoThrow(try SF2Files.validate())
    XCTAssertThrowsError(try SF2Files.validate(expectedResourceCount: 1))
  }

  func testResource() throws {
    for name in names {
      XCTAssertNoThrow(try SF2Files.resource(name: name))
    }
  }

  func testInvalidName() throws {
    XCTAssertThrowsError(try SF2Files.resource(name: "blah"))
  }

  func testAllResources() throws {
    let urls = SF2Files.allResources
    XCTAssertEqual(4, urls.count)
    for name in self.names {
      XCTAssertNotNil(urls.first { $0.lastPathComponent.hasPrefix(name) })
    }
  }
}
