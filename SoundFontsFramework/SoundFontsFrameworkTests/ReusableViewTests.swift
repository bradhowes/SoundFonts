// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

private class FooView: UIView, ReusableView {}
private class BarView: UIView, ReusableView {}

class ReusableViewTests: XCTestCase {

  func testName() {
    XCTAssertTrue(FooView.reuseIdentifier.hasSuffix("FooView"))
    XCTAssertTrue(BarView.reuseIdentifier.hasSuffix("BarView"))
  }
}
