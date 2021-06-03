// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class PresetConfigTests: XCTestCase {

  func testDefaultIsVisible() {
    let p = PresetConfig(name: "one")
    XCTAssertNil(p.isHidden)
    XCTAssertTrue(p.isVisible)
  }

  func testOppositeIsHidden() {
    var p = PresetConfig(name: "one")
    p.isHidden = false
    XCTAssertEqual(p.isHidden, false)
    XCTAssertTrue(p.isVisible)
    p.isHidden = true
    XCTAssertEqual(p.isHidden, true)
    XCTAssertFalse(p.isVisible)
  }
}
