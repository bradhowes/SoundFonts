// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class WhiteSpaceOnlyIsNilTests: XCTestCase {

  func testTrimming() {
    XCTAssertNil(Optional<String>(nil)?.trimmedWhiteSpacesOrNil)
    XCTAssertNil("".trimmedWhiteSpacesOrNil)
    XCTAssertNil("               ".trimmedWhiteSpacesOrNil)
    XCTAssertEqual("foo".trimmedWhiteSpacesOrNil, "foo")
    XCTAssertEqual("foo ".trimmedWhiteSpacesOrNil, "foo")
    XCTAssertEqual(" foo".trimmedWhiteSpacesOrNil, "foo")
    XCTAssertEqual(" foo ".trimmedWhiteSpacesOrNil, "foo")
  }

  func testSearchBar() {
    let tmp = UISearchBar()
    XCTAssertNil(tmp.searchTerm)
    tmp.text = "foo"
    XCTAssertNotNil(tmp.searchTerm)
  }
}
