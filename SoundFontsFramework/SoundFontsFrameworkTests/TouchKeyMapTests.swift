// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import XCTest

class SamplerMock: NoteProcessor {
  var state = Set<Int>()
  func noteOn(_ note: UInt8, velocity: UInt8) { state.insert(Int(note)) }
  func noteOff(_ note: UInt8) { state.remove(Int(note)) }
}

class TouchKeyMapTests: XCTestCase {

  let settings = Settings()
  var sampler: SamplerMock!
  var map: TouchKeyMap!

  override func setUp() {
    sampler = SamplerMock()
    map = TouchKeyMap()
    map.processor = sampler
  }

  func testAssign() {
    let touch = UITouch()
    XCTAssertEqual(sampler.state.count, 0)
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(sampler.state.count, 1)
    XCTAssertFalse(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(sampler.state.count, 1)
  }

  func testReleaseAll() {
    let touch = UITouch()
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(sampler.state.count, 1)
    map.releaseAll()
    XCTAssertEqual(sampler.state.count, 0)
  }

  func testRelease() {
    let touch1 = UITouch()
    let touch2 = UITouch()
    XCTAssertTrue(map.assign(touch1, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertTrue(map.assign(touch2, key: Key(frame: .zero, note: Note(midiNoteValue: 65), settings: settings)))
    XCTAssertEqual(sampler.state.count, 2)
    map.release(touch1)
    XCTAssertEqual(sampler.state.count, 1)
    XCTAssertFalse(map.assign(touch2, key: Key(frame: .zero, note: Note(midiNoteValue: 65), settings: settings)))
    XCTAssertTrue(map.assign(touch1, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
  }

  func testTouchShift() {
    let touch = UITouch()
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 64), settings: settings)))
    XCTAssertEqual(sampler.state.count, 1)
    XCTAssertTrue(map.assign(touch, key: Key(frame: .zero, note: Note(midiNoteValue: 65), settings: settings)))
    XCTAssertEqual(sampler.state.count, 1)
    XCTAssertFalse(sampler.state.contains(64))
    XCTAssertTrue(sampler.state.contains(65))
  }
}
