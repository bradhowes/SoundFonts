// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

class IconTests: XCTestCase {

  func testViability() {
    for entry in Icon.allCases {
      XCTAssertNotNil(entry.image)
      XCTAssertTrue(!entry.accessibilityLabel.isEmpty)
      XCTAssertTrue(!entry.accessibilityHint.isEmpty)
    }
  }
}
