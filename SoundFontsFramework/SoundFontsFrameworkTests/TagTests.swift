// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
@testable import SoundFontsFramework

class TagTests: XCTestCase {

  func testUserTags() {
    XCTAssertTrue(Tag(name: "Foo").isUserTag)
    XCTAssertTrue(Tag(name: Formatters.strings.allTagName).isUserTag)
    XCTAssertTrue(Tag(name: Formatters.strings.builtInTagName).isUserTag)
  }

  func testSetup() {
    XCTAssertEqual(2, Tag.stockTagSet.count)
    XCTAssertTrue(Tag.stockTagSet.contains(Tag.allTag.key))
    XCTAssertTrue(Tag.stockTagSet.contains(Tag.builtInTag.key))
  }
}
