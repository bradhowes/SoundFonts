// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class WhiteSpaceOnlyIsNilTests: XCTestCase {

  func testAlgo() {
    XCTAssertNil(whiteSpaceOnlyIsNil(nil))
    XCTAssertNil(whiteSpaceOnlyIsNil(""))
    XCTAssertNil(whiteSpaceOnlyIsNil("               "))
    XCTAssertEqual(whiteSpaceOnlyIsNil("foo"), "foo")
    XCTAssertEqual(whiteSpaceOnlyIsNil("foo "), "foo")
    XCTAssertEqual(whiteSpaceOnlyIsNil(" foo"), "foo")
    XCTAssertEqual(whiteSpaceOnlyIsNil(" foo "), "foo")
  }

  func testSearchBar() {
    let tmp = UISearchBar()
    XCTAssertNil(tmp.searchTerm)
    tmp.text = "foo"
    XCTAssertNotNil(tmp.searchTerm)
  }
}
