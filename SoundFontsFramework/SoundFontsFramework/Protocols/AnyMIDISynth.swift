// Copyright © 2019 Brad Howes. All rights reserved.

import AVFoundation
import SoundFontInfoLib
import MorkAndMIDI

/**
 Protocol for any entity that acts as a MIDI synth.
 */
public protocol AnyMIDISynth: PresetLoader {
  var avAudioUnit: AVAudioUnitMIDIInstrument { get }

  var synthGain: Float { get set }
  var synthStereoPan: Float { get set }
  var synthGlobalTuning: Float { get set }

  func noteOff(note: UInt8, velocity: UInt8)
  func noteOn(note: UInt8, velocity: UInt8)
  func polyphonicKeyPressure(note: UInt8, pressure: UInt8)
  func controlChange(controller: UInt8, value: UInt8)
  func programChange(program: UInt8)
  func channelPressure(pressure: UInt8)
  func pitchBendChange(value: UInt16)

  func stopAllNotes()
  func setPitchBendRange(value: UInt8)
}

extension AVAudioUnitSampler: AnyMIDISynth {
  public var avAudioUnit: AVAudioUnitMIDIInstrument { self }

  public var synthGain: Float {
    get { self.masterGain }
    set { self.masterGain = newValue }
  }

  public var synthStereoPan: Float {
    get { self.stereoPan }
    set { self.stereoPan = newValue }
  }

  public var synthGlobalTuning: Float {
    get { self.globalTuning }
    set { self.globalTuning = newValue }
  }

  public func setPitchBendRange(value: UInt8) {
    guard value < 25 else { return }
    sendMIDIEvent(0xB0, data1: 101, data2: 0)
    sendMIDIEvent(0xB0, data1: 100, data2: 0)
    sendMIDIEvent(0xB0, data1: 6, data2: value)
    sendMIDIEvent(0xB0, data1: 38, data2: 0)
  }

  public func stopAllNotes() {
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0)
    reset()
  }

  @inlinable
  public func noteOff(note: UInt8, velocity: UInt8) {
    stopNote(note, onChannel: 0)
  }

  @inlinable
  public func noteOn(note: UInt8, velocity: UInt8) {
    startNote(note, withVelocity: velocity, onChannel: 0)
  }

  @inlinable
  public func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
    sendPressure(forKey: note, withValue: pressure, onChannel: 0)
  }

  @inlinable
  public func controlChange(controller: UInt8, value: UInt8) {
    sendController(controller, withValue: value, onChannel: 0)
  }

  @inlinable
  public func pitchBendChange(value: UInt16) {
    sendPitchBend(value, onChannel: 0)
  }

  @inlinable
  public func channelPressure(pressure: UInt8) {
    sendPressure(pressure, onChannel: 0)
  }

  @inlinable
  public func programChange(program: UInt8) {
    sendProgramChange(program, onChannel: 0)
  }
}

extension AVSF2Engine: AnyMIDISynth {

  public func setPitchBendRange(value: UInt8) {}

  public func stopAllNotes() { sf2Engine.stopAllNotes() }

  @inlinable
  public func noteOff(note: UInt8, velocity: UInt8) { sf2Engine.stopNote(note: note, velocity: velocity) }

  @inlinable
  public func noteOn(note: UInt8, velocity: UInt8) { sf2Engine.startNote(note: note, velocity: velocity) }

  @inlinable
  public func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {}

  @inlinable
  public func controlChange(controller: UInt8, value: UInt8) {}

  @inlinable
  public func pitchBendChange(value: UInt16) {}

  @inlinable
  public func channelPressure(pressure: UInt8) {}

  @inlinable
  public func programChange(program: UInt8) {}

  public func loadAndActivatePreset(_ preset: Preset, from url: URL) -> NSError? {
    sf2Engine.load(url)
    sf2Engine.selectPreset(Int32(preset.soundFontIndex))
    return nil
  }
}
