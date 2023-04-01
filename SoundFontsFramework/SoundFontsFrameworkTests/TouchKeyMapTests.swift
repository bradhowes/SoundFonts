// Copyright © 2020 Brad Howes. All rights reserved.

import AVKit
@testable import SoundFontsFramework
import XCTest

class SynthMock: SynthProvider, AnyMIDISynth {
  var avAudioUnit: AVAudioUnitMIDIInstrument { return synth!.avAudioUnit }
  var synthGain: Float = 1.0
  var synthStereoPan: Float = 1.0
  var synthGlobalTuning: Float = 1.0

  func noteOff(note: UInt8, velocity: UInt8) { state.remove(note) }
  func noteOn(note: UInt8, velocity: UInt8) { state.insert(note) }

  func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {}
  func controlChange(controller: UInt8, value: UInt8) {}
  func programChange(program: UInt8) {}
  func channelPressure(pressure: UInt8) {}
  func pitchBendChange(value: UInt16) {}
  func stopAllNotes() {}
  func setPitchBendRange(value: UInt8) {}
  func loadAndActivatePreset(_ preset: SoundFontsFramework.Preset, from url: URL) -> NSError? { nil }

  var synth: AnyMIDISynth? { return self }
  var state = Set<UInt8>()
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
