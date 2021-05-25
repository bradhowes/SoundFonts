// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class Monitor {
    var token: SubscriberToken?
}

enum Event {
    case one
    case two
}

class SubscriptionManagerTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testConnetivity() {
        let sm = SubscriptionManager<Event>()
        let monitor = Monitor()
        let exp1 = expectation(description: "received 'one' notification")
        let exp2 = expectation(description: "received 'two' notification")

        monitor.token = sm.subscribe(monitor) { event in
            switch event {
            case .one: exp1.fulfill()
            case .two: exp2.fulfill()
            }
        }

        sm.notify(.one)
        sm.notify(.two)

        // wait(for: [exp1, exp2], timeout: 0.25)
        waitForExpectations(timeout: 0.25)
    }

    func testUnsubscribe() {
        let sm = SubscriptionManager<Event>()
        let monitor = Monitor()
        let exp1 = expectation(description: "received 'one' notification")
        let exp2 = expectation(description: "received 'two' notification")
        exp2.isInverted = true

        monitor.token = sm.subscribe(monitor) { event in
            switch event {
            case .one: exp1.fulfill()
            case .two: exp2.fulfill()
            }
        }

        sm.notify(.one)
        monitor.token?.unsubscribe()
        sm.notify(.two)

        waitForExpectations(timeout: 0.25)
    }

    func testAutoUnsubscribe() {
        let sm = SubscriptionManager<Event>()
        let exp1 = expectation(description: "received 'one' notification")
        let exp2 = expectation(description: "received 'two' notification")
        exp2.isInverted = true

        do {
            let monitor = Monitor()
            monitor.token = sm.subscribe(monitor) { event in
                switch event {
                case .one: exp1.fulfill()
                case .two: exp2.fulfill()
                }
            }

            sm.notify(.one)
        }

        sm.notify(.two)

        waitForExpectations(timeout: 0.25)
    }
}
