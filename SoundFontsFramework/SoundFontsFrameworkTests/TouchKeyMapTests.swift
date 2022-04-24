// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class SynthMock: KeyboardNoteProcessor {
  var state = Set<UInt8>()
  func startNote(note: UInt8, velocity: UInt8, channel: UInt8) { state.insert(note) }
  func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) { state.remove(note) }
}

class TouchKeyMapTests: XCTestCase {

  let settings = Settings()
  var synth: SynthMock!
  var map: TouchKeyMap!

  override func setUp() {
    synth = SynthMock()
    map = TouchKeyMap()
    map.processor = synth
  }

  func testAssign() {
    let touch = UITouch()
    XCTAssertEqual(synth.state.count, 0)
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(synth.state.count, 1)
    XCTAssertFalse(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(synth.state.count, 1)
  }

  func testReleaseAll() {
    let touch = UITouch()
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(synth.state.count, 1)
    map.releaseAll()
    XCTAssertEqual(synth.state.count, 0)
  }

  func testRelease() {
    let touch1 = UITouch()
    let touch2 = UITouch()
    XCTAssertTrue(map.assign(touch1, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertTrue(map.assign(touch2, key: Key(frame: .zero, note: Note(midiNoteValue: 65), settings: settings)))
    XCTAssertEqual(synth.state.count, 2)
    map.release(touch1)
    XCTAssertEqual(synth.state.count, 1)
    XCTAssertFalse(map.assign(touch2, key: Key(frame: .zero, note: Note(midiNoteValue: 65), settings: settings)))
    XCTAssertTrue(map.assign(touch1, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
  }

  func testTouchShift() {
    let touch = UITouch()
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(synth.state.count, 1)
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 65), settings: settings)))
    XCTAssertEqual(synth.state.count, 1)
    XCTAssertFalse(synth.state.contains(64))
    XCTAssertTrue(synth.state.contains(65))
  }
}
