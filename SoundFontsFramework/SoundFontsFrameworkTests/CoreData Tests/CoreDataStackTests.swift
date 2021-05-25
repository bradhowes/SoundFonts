// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework
import SoundFontInfoLib
import CoreData

class CoreDataStackTests: XCTestCase {

    func testAnnounceWhenCoreDataIsReady() {
        doWhenCoreDataReady(#function) { cdth, context in }
    }

    func testAsyncWaitsInBlock() {
        doWhenCoreDataReady(#function) { cdth, context in
            let exp = XCTestExpectation(description: "invalid")
            let waiter = XCTWaiter()
            DispatchQueue.global(qos: .background).asyncLater(interval: .milliseconds(5)) { exp.fulfill() }
            let result = waiter.wait(for: [exp], timeout: 10.0)
            XCTAssertNotEqual(result, XCTWaiter.Result.timedOut)
        }
    }
}
