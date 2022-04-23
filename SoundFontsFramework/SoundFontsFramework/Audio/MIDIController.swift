// Copyright © 2020 Brad Howes. All rights reserved.

import os

/**
 A controller that processes external MIDI events. Shows keys being played if given a Keyboard, and sends MIDI note
 actions to a synth.
 */
public final class MIDIController {
  private lazy var log = Logging.logger("MIDIController")

  /// Current MIDI channel to listen to for MIDI. A value of -1 means OMNI -- respond to all messages
  public private(set) var channel: Int

  private let synth: Synth
  private let keyboard: AnyKeyboard?
  private let settings: Settings
  private var observer: NSKeyValueObservation?

  /**
   Construct new controller for a synth and keyboard

   - parameter synth: the synth to command
   - parameter keyboard: the Keyboard to update
   */
  public init(synth: Synth, keyboard: AnyKeyboard?, settings: Settings) {
    self.synth = synth
    self.keyboard = keyboard
    self.settings = settings
    self.channel = settings.midiChannel
    monitorMIDIChannelValue()
  }

  private func monitorMIDIChannelValue() {
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

extension MIDIController: MIDIReceiver {

  public func noteOff(note: UInt8, velocity: UInt8) {
    synth.noteOff(note)
    keyboard?.noteIsOff(note: note)
  }

  public func noteOn(note: UInt8, velocity: UInt8) {
    synth.noteOn(note, velocity: velocity)
    keyboard?.noteIsOn(note: note)
  }

  public func allNotesOff() {
    keyboard?.releaseAllKeys()
  }

  public func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
    synth.polyphonicKeyPressure(note, pressure: pressure)
  }

  public func channelPressure(pressure: UInt8) {
    synth.channelPressure(pressure)
  }

  public func pitchBendChange(value: UInt16) {
    synth.pitchBendChange(value)
  }

  public func controlChange(controller: UInt8, value: UInt8) {
    synth.controlChange(controller, value: value)
  }

  public func programChange(program: UInt8) {
    synth.programChange(program)
  }
}
