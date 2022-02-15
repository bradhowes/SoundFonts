// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import XCTest

private class Monitor {
  var token: SubscriberToken?
}

private enum Event: CustomStringConvertible {
  case one
  case two

  public var description: String {
    switch self {
    case .one: return "one"
    case .two: return "two"
    }
  }
}

class SubscriptionManagerTests: XCTestCase {

  override func setUp() {}

  override func tearDown() {}

  func testConnectivity() {
    let manager = SubscriptionManager<Event>()
    let monitor = Monitor()
    let expectation1 = expectation(description: "received 'one' notification")
    let expectation2 = expectation(description: "received 'two' notification")

    monitor.token = manager.subscribe(monitor) { event in
      switch event {
      case .one: expectation1.fulfill()
      case .two: expectation2.fulfill()
      }
    }

    manager.notify(.one)
    manager.notify(.two)

    wait(for: [expectation1, expectation2], timeout: 30.0)
  }

  func testUnsubscribe() {
    let manager = SubscriptionManager<Event>()
    let monitor = Monitor()
    XCTAssertEqual(manager.notify(.one), 0)
    monitor.token = manager.subscribe(monitor) { _ in }
    XCTAssertEqual(manager.notify(.one), 1)
    monitor.token?.unsubscribe()
    XCTAssertEqual(manager.notify(.two), 0)
  }

  func disable_testAutoUnsubscribe() {
    let manager = SubscriptionManager<Event>()
    do {
      let monitor = Monitor()
      monitor.token = manager.subscribe(monitor) { event in }
      XCTAssertEqual(manager.notify(.one), 1)
    }
    XCTAssertEqual(manager.notify(.one), 0)
  }
}
