// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class TimerTests: XCTestCase {

    func testOnceAfter() {
        let expectation = self.expectation(description: "once after fired")
        let start = Date()
        let timer = Timer.once(after: 100.milliseconds) { timer in
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertEqual(elapsed, 0.1, accuracy: 0.01)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 0.2)
        XCTAssertFalse(timer.isValid, "expected invalid timer")
    }

    func testOnceWhen() {
        let expectation = self.expectation(description: "once when fired")
        let start = Date()
        let when = Date().addingTimeInterval(100.milliseconds)
        let timer = Timer.once(when: when) { timer in
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertEqual(elapsed, 0.1, accuracy: 0.01)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 0.25)
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

        self.waitForExpectations(timeout: 0.04)
    }
}
