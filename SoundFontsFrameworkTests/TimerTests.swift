// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class TimerTests: XCTestCase {

    func testOnceAfter() {
        let expectation = self.expectation(description: "once after fired")
        let start = Date()
        let timer = Timer.once(after: 1.second) { timer in
            let elapsed = start.timeIntervalSince(Date())
            XCTAssertEqual(elapsed, -1.0, accuracy: 0.006)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5.0)
        XCTAssertFalse(timer.isValid, "expected invalid timer")
    }

    func testOnceWhen() {
        let expectation = self.expectation(description: "once when fired")
        let start = Date()
        let when = Date().addingTimeInterval(500.milliseconds)
        let timer = Timer.once(when: when) { timer in
            let elapsed = start.timeIntervalSince(Date())
            XCTAssertEqual(elapsed, -0.5, accuracy: 0.05)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 5.0)
        XCTAssertFalse(timer.isValid, "expected invalid timer")
    }

    func testEvery() {
        let expectation = self.expectation(description: "every fired twice")
        var count = 0
        Timer.every(10.milliseconds) { timer in
            count += 1
            if count >= 2 {
                timer.invalidate()
                expectation.fulfill()
            }
        }

        self.waitForExpectations(timeout: 5.0)
    }
}
