// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

class ChangesCompilerTests: XCTestCase {
  func testRecent() {
    let found = ChangesCompiler.compile()
    XCTAssertTrue(found.count >= 20)
  }
}
