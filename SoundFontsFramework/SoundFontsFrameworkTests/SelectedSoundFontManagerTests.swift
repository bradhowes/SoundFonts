// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import SoundFontInfoLib
import XCTest

class SelectedSoundFontManagerTests: XCTestCase {

  let soundFontInfo = SoundFontInfo(
    "name",
    url: URL(fileURLWithPath: "/a/b/c"),
    author: "author",
    comment: "comment",
    copyright: "copyright",
    presets: [
      SoundFontInfoPreset("a", bank: 1, preset: 1),
      SoundFontInfoPreset("b", bank: 1, preset: 2)
    ]
  )

  lazy var soundFont = SoundFont("name", soundFontInfo: soundFontInfo!, resource: URL(fileURLWithPath: "a/b/c"))

  func testSetting() {
    let manager = SelectedSoundFontManager()

    let monitor = Monitor()
    monitor.token = manager.subscribe(monitor, notifier: monitor.closure)

    monitor.makeExpectation()
    manager.setSelected(soundFont)

    // Repeated setSelected with same font does not fire
    monitor.makeExpectation(inverted: true)
    manager.setSelected(soundFont)

    monitor.makeExpectation()
    manager.clearSelected()

    // Repeated clearSelected does not fire
    monitor.makeExpectation(inverted: true)
    manager.clearSelected()

    monitor.makeExpectation()
    manager.setSelected(soundFont)

    wait(for: monitor.expectations, timeout: 30.0)
    XCTAssertEqual(monitor.counter, 3)
  }
}

private class Monitor {
  var token: SubscriberToken?
  var counter = 0
  var expectations = [XCTestExpectation]()

  func closure(event: SelectedSoundFontEvent) {
    switch event {
    case let .changed(old, new):
      XCTAssertNotEqual(old, new)
      counter += 1
      expectations.last!.fulfill()
    }
  }

  func makeExpectation(inverted: Bool = false) {
    let expectation = XCTestExpectation(description: "\(expectations.count + 1)")
    expectations.append(expectation)
    expectation.isInverted = inverted
    expectation.expectedFulfillmentCount = 1
  }
}
