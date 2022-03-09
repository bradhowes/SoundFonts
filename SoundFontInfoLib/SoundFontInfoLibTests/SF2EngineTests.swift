// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest
import SoundFontInfoLib
import SF2Files

class SF2EngineTests: XCTestCase {

  let names = ["FluidR3_GM", "FreeFont", "GeneralUser GS MuseScore v1.442", "RolandNicePiano"]
  let urls: [URL] = SF2Files.allResources.sorted { $0.lastPathComponent < $1.lastPathComponent }

  func testCreating() {
    let engine = SF2Engine(32)
    XCTAssertEqual(32, engine.voiceCount())
    XCTAssertEqual(0, engine.activeVoiceCount())
  }

  func testLoadingUrls() {
    let engine = SF2Engine(32)
    engine.load(urls[0], preset: 0)
    XCTAssertEqual(189, engine.presetCount())

    engine.load(urls[1], preset: 0)
    XCTAssertEqual(235, engine.presetCount())

    engine.load(urls[2], preset: 0)
    XCTAssertEqual(270, engine.presetCount())

    engine.load(urls[3], preset: 0)
    XCTAssertEqual(1, engine.presetCount())
  }

  func testLoadingAllPresets() {
    let engine = SF2Engine(32)
    engine.load(urls[2], preset: 0)
    XCTAssertEqual(270, engine.presetCount())
    for preset in 1..<engine.presetCount() {
      engine.usePreset(preset)
    }
  }

  func testLoadingTimes() {
    measure {
      let engine = SF2Engine(32)
      engine.load(urls[2], preset: 0)
    }
  }

  func testNoteOn() {
    let engine = SF2Engine(32)
    engine.load(urls[2], preset: 0)
    engine.note(on: 69, velocity: 64)
    XCTAssertEqual(1, engine.activeVoiceCount())
    engine.note(on: 69, velocity: 64)
    XCTAssertEqual(2, engine.activeVoiceCount())
    engine.noteOff(69)
    XCTAssertEqual(2, engine.activeVoiceCount())
    engine.allOff()
    XCTAssertEqual(0, engine.activeVoiceCount())
  }
}
