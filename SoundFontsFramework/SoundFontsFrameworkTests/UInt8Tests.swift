// Copyright © 2023 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class UInt8Tests : XCTestCase {

  func testNibbleHigh() {
    XCTAssertEqual(UInt8(0x0F).nibbleHigh, 0x00)
    XCTAssertEqual(UInt8(0xFF).nibbleHigh, 0xF0)
    XCTAssertEqual(UInt8(0x12).nibbleHigh, 0x10)
  }

  func testNibbleLow() {
    XCTAssertEqual(UInt8(0xF0).nibbleLow, 0x00)
    XCTAssertEqual(UInt8(0xFF).nibbleLow, 0x0F)
    XCTAssertEqual(UInt8(0x21).nibbleLow, 0x01)
  }
}
