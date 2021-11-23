// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

class Foundation_ExtensionsTests: XCTestCase {

  func testDoubleTimes() {
    XCTAssertEqual(1.day, 86400.seconds)
    XCTAssertEqual(5.minutes, 300.seconds)
    XCTAssertEqual(10.seconds, 10000.milliseconds)
    XCTAssertEqual(11.seconds, 11000.ms)
  }
}
