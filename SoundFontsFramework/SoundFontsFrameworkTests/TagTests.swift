// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

class TagTests: XCTestCase {

  func testUserTags() {
    XCTAssertTrue(LegacyTag(name: "Foo").isUserTag)
    XCTAssertTrue(LegacyTag(name: Formatters.strings.allTagName).isUserTag)
    XCTAssertTrue(LegacyTag(name: Formatters.strings.builtInTagName).isUserTag)
  }

  func testSetup() {
    XCTAssertEqual(2, LegacyTag.stockTagSet.count)
    XCTAssertTrue(LegacyTag.stockTagSet.contains(LegacyTag.allTag.key))
    XCTAssertTrue(LegacyTag.stockTagSet.contains(LegacyTag.builtInTag.key))
  }
}
