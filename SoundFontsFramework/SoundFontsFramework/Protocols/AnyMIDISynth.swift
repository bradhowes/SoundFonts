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

public extension MIDIPacket {
  func post(on block: AUScheduleMIDIEventBlock) {
    withUnsafePointer(to: data.0) { ptr in
      block(AUEventSampleTimeImmediate, 0, Int(self.length), ptr)
    }
  }
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
    guard let midiBlock = self.sf2Engine.scheduleMIDIEventBlock else { fatalError("nil MIDI schedule block") }
    let packet = MIDIPacket.Builder(timestamp: 0, msg: .noteOn, data1: note, data2: velocity).packet
    packet.post(on: midiBlock)
  }

  @inlinable
  public func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    guard let midiBlock = self.sf2Engine.scheduleMIDIEventBlock else { fatalError("nil MIDI schedule block") }
    let packet = MIDIPacket.Builder(timestamp: 0, msg: .noteOff, data1: note, data2: velocity).packet
    packet.post(on: midiBlock)
  }

  @inlinable
  public func stopAllNotes() {
    guard let midiBlock = self.sf2Engine.scheduleMIDIEventBlock else { fatalError("nil MIDI schedule block") }
    let packet = MIDIPacket.Builder(timestamp: 0, msg: .reset).packet
    packet.post(on: midiBlock)
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
