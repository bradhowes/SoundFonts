// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest


private class FooView: UIView, NibLoadableView {}

class NibLoadableViewTests: XCTestCase {

  func testBasic() {
    XCTAssertTrue(FooView.nibName.hasSuffix("FooView"))
    XCTAssertNotNil(FooView.nib)
  }
}
