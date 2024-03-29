// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import SoundFontInfoLib
import SoundFontsFramework
import XCTest

class CoreDataStackTests: XCTestCase {

  func testAnnounceWhenCoreDataIsReady() {
    doWhenCoreDataReady(#function) { testHarness, context in }
  }

  func testAsyncWaitsInBlock() {
    doWhenCoreDataReady(#function) { testHarness, context in
      let expectation = XCTestExpectation(description: "invalid")
      let waiter = XCTWaiter()
      DispatchQueue.global(qos: .background).asyncLater(interval: .milliseconds(5)) {
        expectation.fulfill()
      }
      let result = waiter.wait(for: [expectation], timeout: 30.0)
      XCTAssertNotEqual(result, XCTWaiter.Result.timedOut)
    }
  }
}
