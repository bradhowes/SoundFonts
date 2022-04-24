// Copyright © 2019 Brad Howes. All rights reserved.

import AVFoundation

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

  public func stopAllNotes() {
    self.reset()
  }

  public func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    startNote(note, withVelocity: velocity, onChannel: channel)
  }

  public func stopNote(note: UInt8, channel: UInt8) { stopNote(note, onChannel: channel) }

  public func setController(_ controller: UInt8, value: UInt8, channel: UInt8) {
    sendController(controller, withValue: value, onChannel: channel)
  }

  public func setPitchBend(_ value: UInt16, channel: UInt8) { sendPitchBend(value, onChannel: channel) }
  public func setAllKeysPressure(_ pressure: UInt8, channel: UInt8) { sendPressure(pressure, onChannel: channel) }
  public func setKeyPressure(_ key: UInt8, pressure: UInt8, channel: UInt8) {
    sendPressure(forKey: key, withValue: pressure, onChannel: channel)
  }

  public func changeProgram(_ program: UInt8, channel: UInt8) {
    sendProgramChange(program, onChannel: channel)
  }

  public func changeProgram(_ program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {
    sendProgramChange(program, bankMSB: bankMSB, bankLSB: bankLSB, onChannel: channel)
  }

  public func processMIDIEvent(_ midiStatus: UInt8, data1: UInt8) {
    sendMIDIEvent(midiStatus, data1: data1)
  }

  public func processMIDIEvent(_ midiStatus: UInt8, data1: UInt8, data2: UInt8) {
    sendMIDIEvent(midiStatus, data1: data1, data2: data2)
  }
}
