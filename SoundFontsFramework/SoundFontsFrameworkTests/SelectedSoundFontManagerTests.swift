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

    let expectation1 = expectation(description: "1")
    monitor.expectation = expectation1
    manager.setSelected(soundFont)
    wait(for: [expectation1], timeout: 10.0)

    let expectation2 = expectation(description: "2")
    expectation2.isInverted = true
    monitor.expectation = expectation2
    manager.setSelected(soundFont)
    wait(for: [expectation2], timeout: 10.0)

    manager.clearSelected()

    let expectation3 = expectation(description: "3")
    expectation3.isInverted = true
    monitor.expectation = expectation3
    manager.clearSelected()
    wait(for: [expectation3], timeout: 10.0)

    let expectation4 = expectation(description: "3")
    monitor.expectation = expectation4
    manager.setSelected(soundFont)

    wait(for: [expectation4], timeout: 10.0)
  }
}

private class Monitor {
  var token: SubscriberToken?
  var expectation: XCTestExpectation!

  func closure(event: SelectedSoundFontEvent) {
    switch event {
    case let .changed(old, new):
      XCTAssertNotEqual(old, new)
      expectation.fulfill()
    }
  }
}
