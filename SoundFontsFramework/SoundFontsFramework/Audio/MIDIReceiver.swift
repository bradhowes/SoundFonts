// Copyright © 2020 Brad Howes. All rights reserved.

import os
import MorkAndMIDI

/**
 A MIDI receiver that processes MIDI events from an external source. Shows the keys being played if given a Keyboard,
 and forwards MIDI commands to a synth.
 */
public final class MIDIReceiver {
  private lazy var log = Logging.logger("MIDIController")

  /// Current MIDI channel to listen to for MIDI. A value of -1 means OMNI -- accept all messages
  public private(set) var channel: Int
  public private(set) var group: Int

  private let audioEngine: AudioEngine
  private let keyboard: AnyKeyboard?
  private let settings: Settings
  private var observer: NSKeyValueObservation?

  private var synth: AnyMIDISynth? { audioEngine.synth }

  /**
   Construct new controller for a synth and keyboard

   - parameter synth: the synth to command
   - parameter keyboard: the Keyboard to update
   */
  public init(audioEngine: AudioEngine, keyboard: AnyKeyboard?, settings: Settings) {
    self.audioEngine = audioEngine
    self.keyboard = keyboard
    self.settings = settings
    self.channel = settings.midiChannel
    self.group = -1
    monitorMIDIChannelValue()
  }

  public func stopAllNotes() {
    keyboard?.releaseAllKeys()
    // synth.stopAllNotes()
  }

  private func monitorMIDIChannelValue() {

    // Watch for changes in the MIDI channel setting so we can continue to properly filter MIDI events after use changes
    // it in the Settings panel.
    self.observer = settings.observe(\.midiChannel) { [weak self] _, _ in
      guard let self = self else { return }
      let value = self.settings.midiChannel
      if value != self.channel {
        os_log(.debug, log: self.log, "new MIDI channel: %d", value)
        self.channel = value
      }
    }
  }
}

extension UInt16 {
  var b0: UInt8 { .init((self >> 8) & 0x00FF) }
  var b1: UInt8 { .init((self     ) & 0x00FF) }
}

extension UInt32 {
  var b0: UInt8 { .init((self >> 24) & 0x00_00_00_FF) }
  var b1: UInt8 { .init((self >> 16) & 0x00_00_00_FF) }
  var b2: UInt8 { .init((self >>  8) & 0x00_00_00_FF) }
  var b3: UInt8 { .init((self      ) & 0x00_00_00_FF) }

  var w0: UInt16 { .init((self >> 16) & 0x00_00_FF_FF)}
  var w1: UInt16 { .init((self      ) & 0x00_00_FF_FF)}
}

extension MIDIReceiver: Receiver {

  public func noteOff(note: UInt8, velocity: UInt8) {
    synth?.noteOff(note: note, velocity: velocity)
    keyboard?.noteIsOff(note: note)
  }

  public func noteOff2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    noteOff(note: note, velocity: velocity.b0)
  }

  public func noteOn(note: UInt8, velocity: UInt8) {
    synth?.noteOn(note: note, velocity: velocity)
    keyboard?.noteIsOn(note: note)
  }

  public func noteOn2(note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    noteOn(note: note, velocity: velocity.b0)
  }

  public func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
    synth?.polyphonicKeyPressure(note: note, pressure: pressure)
  }

  public func polyphonicKeyPressure2(note: UInt8, pressure: UInt32) {
    synth?.polyphonicKeyPressure(note: note, pressure: pressure.b0)
  }

  public func controlChange(controller: UInt8, value: UInt8) {
    synth?.controlChange(controller: controller, value: value)
    os_log(.debug, log: log, "controlCHange: %d - %d", controller, value)
  }

  public func controlChange2(controller: UInt8, value: UInt32) {
    synth?.controlChange(controller: controller, value: value.b0)
    os_log(.debug, log: log, "controlCHange: %d - %d", controller, value)
  }

  public func programChange(program: UInt8) {
    synth?.programChange(program: program)
    os_log(.debug, log: log, "programChange: %d", program)
  }

  public func programChange2(program: UInt8, bank: UInt16) {
    synth?.programChange(program: program)
    os_log(.debug, log: log, "programChange: %d", program)
  }

  public func channelPressure(pressure: UInt8) {
    synth?.channelPressure(pressure: pressure)
  }

  public func channelPressure2(pressure: UInt32) {
    synth?.channelPressure(pressure: pressure.b0)
  }

  public func pitchBendChange(value: UInt16) {
    synth?.pitchBendChange(value: value)
    os_log(.debug, log: log, "pitchBendChange: %d", value)
  }

  public func pitchBendChange2(value: UInt32) {
    synth?.pitchBendChange(value: value.w0 & 0x7FFF)
  }

  public func systemReset() {
    synth?.stopAllNotes()
  }

  public func timeCodeQuarterFrame(value: UInt8) {}
  public func songPositionPointer(value: UInt16) {}
  public func songSelect(value: UInt8) {}
  public func tuneRequest() {}
  public func timingClock() {}
  public func startCurrentSequence() {}
  public func continueCurrentSequence() {}
  public func stopCurrentSequence() {}
  public func activeSensing() {}

  // MIDI v2
  public func perNotePitchBendChange(note: UInt8, value: UInt32) {}
  public func registeredPerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {}
  public func assignablePerNoteControllerChange(note: UInt8, controller: UInt8, value: UInt32) {}
  public func registeredControllerChange(controller: UInt16, value: UInt32) {}
  public func assignableControllerChange(controller: UInt16, value: UInt32) {}
  public func relativeRegisteredControllerChange(controller: UInt16, value: Int32) {}
  public func relativeAssignableControllerChange(controller: UInt16, value: Int32) {}
  public func perNoteManagement(note: UInt8, detach: Bool, reset: Bool) {}
}
