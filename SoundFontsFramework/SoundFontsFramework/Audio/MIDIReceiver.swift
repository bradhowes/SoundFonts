// Copyright © 2020 Brad Howes. All rights reserved.

import os

/**
 A MIDI receiver that processes MIDI events from an external source. Shows the keys being played if given a Keyboard,
 and forwards MIDI commands to a synth.
 */
public final class MIDIReceiver {
  private lazy var log = Logging.logger("MIDIController")

  /// Current MIDI channel to listen to for MIDI. A value of -1 means OMNI -- accept all messages
  public private(set) var channel: Int

  private let synth: SynthManager
  private let keyboard: AnyKeyboard?
  private let settings: Settings
  private var observer: NSKeyValueObservation?

  /**
   Construct new controller for a synth and keyboard

   - parameter synth: the synth to command
   - parameter keyboard: the Keyboard to update
   */
  public init(synth: SynthManager, keyboard: AnyKeyboard?, settings: Settings) {
    self.synth = synth
    self.keyboard = keyboard
    self.settings = settings
    self.channel = settings.midiChannel
    monitorMIDIChannelValue()
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

extension MIDIReceiver: AnyMIDIReceiver {

  private func accepting(_ channel: UInt8) -> Bool {
    self.channel == -1 || self.channel == channel
  }

  public func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.stopNote(note: note, velocity: velocity, channel: channel)
    keyboard?.noteIsOff(note: note)
  }

  public func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.startNote(note: note, velocity: velocity, channel: channel)
    keyboard?.noteIsOn(note: note)
  }

  public func stopAllNotes() {
    keyboard?.releaseAllKeys()
  }

  public func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.setNotePressure(note: note, pressure: pressure, channel: channel)
  }

  public func setPressure(pressure: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.setPressure(pressure: pressure, channel: channel)
  }

  public func setPitchBend(value: UInt16, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.setPitchBend(value: value, channel: channel)
  }

  public func setController(controller: UInt8, value: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.setController(controller: controller, value: value, channel: channel)
  }

  public func changeProgram(program: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.changeProgram(program: program, channel: channel)
  }

  public func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {
    guard accepting(channel) else { return }
    synth.changeProgram(program: program, bankMSB: bankMSB, bankLSB: bankLSB, channel: channel)
  }

  public func processMIDIEvent(status: UInt8, data1: UInt8) {
    synth.processMIDIEvent(status: status, data1: data1)
  }

  public func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {
    synth.processMIDIEvent(status: status, data1: data1, data2: data2)
  }
}
