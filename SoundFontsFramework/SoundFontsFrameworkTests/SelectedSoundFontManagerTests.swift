// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import SoundFontInfoLib
import XCTest

class SelectedSoundFontManagerTests: XCTestCase {

  private var manager: SelectedSoundFontManager!
  private var monitor: Monitor!

  override func setUp() {
    manager = SelectedSoundFontManager()
    monitor = Monitor(manager: manager)
  }

  let soundFontInfo = SoundFontInfo(
    "name",
    url: URL(fileURLWithPath: "/a/b/c"),
    author: "author",
    comment: "comment",
    copyright: "copyright",
    presets: [
      SoundFontInfoPreset("a", bank: 1, program: 1),
      SoundFontInfoPreset("b", bank: 1, program: 2)
    ]
  )

  lazy var soundFont = SoundFont("name", soundFontInfo: soundFontInfo!, resource: URL(fileURLWithPath: "a/b/c"))

  func testAPI() {
    monitor.expectation = expectation(description: "saw set")
    manager.setSelected(soundFont)
    wait(for: [monitor.expectation], timeout: 10.0)

    monitor.expectation = expectation(description: "did not see duplicate set")
    monitor.expectation.isInverted = true
    manager.setSelected(soundFont)
    wait(for: [monitor.expectation], timeout: 10.0)

    monitor.expectation = expectation(description: "saw clear")
    manager.clearSelected()
    wait(for: [monitor.expectation], timeout: 10.0)

    monitor.expectation = expectation(description: "did not see duplicate clear")
    monitor.expectation.isInverted = true
    manager.clearSelected()
    wait(for: [monitor.expectation], timeout: 10.0)

    monitor.expectation = expectation(description: "saw set after clear")
    manager.setSelected(soundFont)
    wait(for: [monitor.expectation], timeout: 10.0)
  }
}

private class Monitor {
  var token: SubscriberToken?
  var expectation: XCTestExpectation!

  init(manager: SelectedSoundFontManager) {
    self.token = manager.subscribe(self, notifier: closure(event:))
  }

  func closure(event: SelectedSoundFontEvent) {
    switch event {
    case let .changed(old, new):
      XCTAssertNotEqual(old, new)
      expectation.fulfill()
    }
  }
}
