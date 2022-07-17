// Copyright © 2019 Brad Howes. All rights reserved.

import AVFoundation
import SoundFontInfoLib

/**
 Protocol for any entity that acts as a MIDI synth.
 */
public protocol AnyMIDISynth: AnyMIDIReceiver, PresetLoader {

  var avAudioUnit: AVAudioUnitMIDIInstrument { get }

  var synthGain: Float { get set }
  var synthStereoPan: Float { get set }
  var synthGlobalTuning: Float { get set }

  func reset()
}

extension AVSF2Engine: AnyMIDISynth {

  @inlinable
  public func reset() {
    AudioUnitReset(avAudioUnit.audioUnit, kAudioUnitScope_Global, 0)
    avAudioUnit.reset()
  }

  public func loadAndActivatePreset(_ preset: Preset, from url: URL) -> NSError? {
    sf2Engine.load(url)
    sf2Engine.selectPreset(Int32(preset.program))
    return nil
  }

  @inlinable
  public func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    sf2Engine.startNote(note: note, velocity: velocity)
  }

  @inlinable
  public func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    sf2Engine.stopNote(note: note, velocity: velocity)
  }

  @inlinable
  public func stopAllNotes() {
    sf2Engine.stopAllNotes()
    reset()
  }

  public func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {}
  public func setController(controller: UInt8, value: UInt8, channel: UInt8) {}
  public func changeProgram(program: UInt8, channel: UInt8) {}
  public func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {}
  public func setPressure(pressure: UInt8, channel: UInt8) {}
  public func setPitchBend(value: UInt16, channel: UInt8) {}
  public func processMIDIEvent(status: UInt8, data1: UInt8) {}
  public func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {}
}

extension AVAudioUnitSampler: AnyMIDISynth {

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

  public var avAudioUnit: AVAudioUnitMIDIInstrument { self }

  @inlinable
  public func stopAllNotes() {
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0)
    self.reset()
  }

  @inlinable
  public func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    startNote(note, withVelocity: velocity, onChannel: channel)
  }

  @inlinable
  public func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    stopNote(note, onChannel: channel)
  }

  @inlinable
  public func setController(controller: UInt8, value: UInt8, channel: UInt8) {
    sendController(controller, withValue: value, onChannel: channel)
  }

  @inlinable
  public func setPitchBend(value: UInt16, channel: UInt8) { sendPitchBend(value, onChannel: channel) }

  @inlinable
  public func setPressure(pressure: UInt8, channel: UInt8) { sendPressure(pressure, onChannel: channel) }

  @inlinable
  public func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {
    sendPressure(forKey: note, withValue: pressure, onChannel: channel)
  }

  @inlinable
  public func changeProgram(program: UInt8, channel: UInt8) {
    sendProgramChange(program, onChannel: channel)
  }

  @inlinable
  public func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {
    sendProgramChange(program, bankMSB: bankMSB, bankLSB: bankLSB, onChannel: channel)
  }

  @inlinable
  public func processMIDIEvent(status: UInt8, data1: UInt8) {
    sendMIDIEvent(status, data1: data1)
  }

  @inlinable
  public func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {
    sendMIDIEvent(status, data1: data1, data2: data2)
  }
}
