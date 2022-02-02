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

  override func setUp() {
  }

  override func tearDown() {
  }

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
    waitForExpectations(timeout: 10.0)
  }

  func testUnsubscribe() {
    let manager = SubscriptionManager<Event>()
    let monitor = Monitor()
    let expectation1 = expectation(description: "received 'one' notification")
    let expectation2 = expectation(description: "received 'two' notification")
    expectation2.isInverted = true

    monitor.token = manager.subscribe(monitor) { event in
      switch event {
      case .one: expectation1.fulfill()
      case .two: expectation2.fulfill()
      }
    }

    manager.notify(.one)
    monitor.token?.unsubscribe()
    manager.notify(.two)

    waitForExpectations(timeout: 1.0)
  }

  func testAutoUnsubscribe() {
    let manager = SubscriptionManager<Event>()
    let expectation1 = expectation(description: "received 'one' notification")
    let expectation2 = expectation(description: "received 'two' notification")
    expectation2.isInverted = true

    do {
      let monitor = Monitor()
      monitor.token = manager.subscribe(monitor) { event in
        switch event {
        case .one: expectation1.fulfill()
        case .two: expectation2.fulfill()
        }
      }

      manager.notify(.one)
    }

    manager.notify(.two)

    waitForExpectations(timeout: 1.0)
  }
}
