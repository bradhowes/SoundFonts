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
            DispatchQueue.global(qos: .background).asyncLater(interval: .milliseconds(5)) { exp.fulfill() }
            let waiter = XCTWaiter()
            let result = waiter.wait(for: [exp], timeout: 1.0)
            XCTAssertEqual(result, XCTWaiter.Result.completed)
        }
    }
}
