// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

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

  func testVersionComponents() {
    XCTAssertEqual(VersionComponents(major: 1, minor: 2, patch: 3), "1.2.3".versionComponents)
    XCTAssertEqual(VersionComponents(major: 0, minor: 0, patch: 0), "".versionComponents)
    XCTAssertEqual(VersionComponents(major: 1, minor: 0, patch: 0), "1.a.b.c.d".versionComponents)
    XCTAssertEqual(VersionComponents(major: 1, minor: 2, patch: 0), "1.2".versionComponents)
    XCTAssertEqual(VersionComponents(major: 1, minor: 2, patch: 3), "1.2.3".versionComponents)
    XCTAssertEqual(VersionComponents(major: 1, minor: 2, patch: 3), "1.2.3.4".versionComponents)
    XCTAssertEqual(
      VersionComponents(major: 1, minor: 2, patch: 3), "1.2.3 (1234)".versionComponents)

    XCTAssertTrue("1.2.2".versionComponents < "1.2.3".versionComponents)
    XCTAssertTrue("1.2.2".versionComponents <= "1.2.3".versionComponents)
    XCTAssertTrue("1.2.3".versionComponents == "1.2.3".versionComponents)
    XCTAssertTrue("1.2.3".versionComponents >= "1.2.3".versionComponents)
    XCTAssertTrue("1.2.4".versionComponents >= "1.2.3".versionComponents)
    XCTAssertTrue("1.2.4".versionComponents > "1.2.3".versionComponents)

    XCTAssertTrue("1".versionComponents < "1.1".versionComponents)
    XCTAssertTrue("1.2".versionComponents > "1.1.99".versionComponents)
    XCTAssertTrue("2".versionComponents > "1.999.999".versionComponents)
    XCTAssertTrue("2.1.9".versionComponents < "2.2".versionComponents)
  }
}
