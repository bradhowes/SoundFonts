// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class StringTests: XCTestCase {

    func testHappyPath() {
        let path = "fileName_E621E1F8-C36C-495A-93FC-0C247A3E6E5F.sf2"
        let (a, b) = path.stripEmbeddedUUID()
        XCTAssertEqual(a, "fileName.sf2")
        XCTAssertEqual(b?.uuidString, "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
    }

    func testUUIDWrongLength() {
        let path = "fileName_E62E1F8-C36C-495A-93FC-0C247A3E6E5F.sf2"
        let (a, b) = path.stripEmbeddedUUID()
        XCTAssertEqual(a, path)
        XCTAssertNil(b)
    }

    func testUUIDInvalidCharacter() {
        let path = "fileName_E621E1F8-c36C-495A-93FC-0C247A3E6E5F.sf2"
        let (a, b) = path.stripEmbeddedUUID()
        XCTAssertEqual(a, path)
        XCTAssertNil(b)
    }
}
