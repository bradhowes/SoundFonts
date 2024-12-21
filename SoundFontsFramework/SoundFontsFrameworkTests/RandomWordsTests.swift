// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

@testable import SoundFontsFramework

class RandomWordsTests: XCTestCase {

  func testZeroHash() {
    let hash = 0
    XCTAssertEqual("resink", RandomWords.randomWord(hash: hash))
  }

  func testRepeatedHash() {
    let hash = 123_456
    XCTAssertEqual("erinaceous", RandomWords.randomWord(hash: hash))
  }

  func testNegativeHash() {
    let hash = -123
    XCTAssertEqual("sixpence", RandomWords.randomWord(hash: hash))
  }

  func testPositiveHash() {
    let hash = 123
    XCTAssertEqual("overtwine", RandomWords.randomWord(hash: hash))
  }

  func testLargeNegativeHash() {
    let hash = -123_456_789
    XCTAssertEqual("deforciant", RandomWords.randomWord(hash: hash))
  }

  func testLargePositiveHash() {
    let hash = 123_456_789
    XCTAssertEqual("premake", RandomWords.randomWord(hash: hash))
  }
}
