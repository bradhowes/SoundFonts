// Copyright © 2020 Brad Howes. All rights reserved.

import os
import CoreMIDI
import MorkAndMIDI

/**
 A MIDI receiver that processes MIDI events from an external source. Shows the keys being played if given a Keyboard,
 and forwards MIDI commands to a synth.
 */
final public class MIDIReceiver {
  private lazy var log = Logging.logger("MIDIController")

  public struct Payload: CustomStringConvertible {
    public var description: String { "\(source) \(controller)" }
    let source: MIDIUniqueID
    let controller: UInt8
  }

  private let settings: Settings
  private let activityNotifier = ActivityNotifier()

  private(set) var midiControllerState: [MIDIControllerState] = []

  /// Current MIDI channel to listen to for MIDI. A value of -1 means OMNI -- accept all messages
  public private(set) var channel: Int
  public private(set) var group: Int

  public var audioEngine: AudioEngine?

  private let keyboard: AnyKeyboard
  private let midiMonitor: MIDIMonitor
  private var observer: NSKeyValueObservation?
  private var synth: AnyMIDISynth? { audioEngine?.synth }

  /**
   Construct new controller for a synth and keyboard

   - parameter synth: the synth to command
   - parameter keyboard: the Keyboard to update
   */
  public init(audioEngine: AudioEngine, keyboard: AnyKeyboard, settings: Settings, midiMonitor: MIDIMonitor) {
    self.audioEngine = audioEngine
    self.keyboard = keyboard
    self.settings = settings
    self.midiMonitor = midiMonitor
    self.channel = settings.midiChannel
    self.group = -1
    monitorMIDIChannelValue()

    midiControllerState = (UInt8(0)...UInt8(127)).map {
      MIDIControllerState(identifier: $0, allowed: controllerAllowed($0))
    }
  }

  public func stopAllNotes() {
    keyboard.releaseAllKeys()
    // synth.stopAllNotes()
  }

  public func addMonitor(block: @escaping (Payload) -> Void) -> NotificationObserver {
    activityNotifier.addMonitor(block: block)
  }

  private func controllerSettingKey(for controller: UInt8) -> String { "controllerAllowed\(controller)" }

  private func controllerAllowed(_ controller: UInt8) -> Bool {
    settings.get(key: controllerSettingKey(for: controller), defaultValue: true)
  }

  func allowedStateChanged(controller: UInt8, allowed: Bool) {
    settings.set(key: controllerSettingKey(for: controller), value: allowed)
    midiControllerState[Int(controller)].allowed = allowed
    if let lastValue = midiControllerState[Int(controller)].lastValue, allowed {
      synth?.controlChange(controller: controller, value: lastValue)
    }
  }

  private func monitorMIDIChannelValue() {

    // Watch for changes in the MIDI channel setting so we can continue to properly filter MIDI events after user changes
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

  public func noteOff(source: MIDIUniqueID, note: UInt8, velocity: UInt8) {
    synth?.noteOff(note: note, velocity: velocity)
    keyboard.noteIsOff(note: note)
  }

  public func noteOff2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    noteOff(source: source, note: note, velocity: velocity.b0)
  }

  public func noteOn(source: MIDIUniqueID, note: UInt8, velocity: UInt8) {
    let connectionState = midiMonitor.connectionState(for: source)
    synth?.noteOn(note: note, velocity: connectionState.fixedVelocity ?? velocity)
    keyboard.noteIsOn(note: note)
  }

  public func noteOn2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    noteOn(source: source, note: note, velocity: velocity.b0)
  }

  public func polyphonicKeyPressure(source: MIDIUniqueID, note: UInt8, pressure: UInt8) {
    synth?.polyphonicKeyPressure(note: note, pressure: pressure)
  }

  public func polyphonicKeyPressure2(source: MIDIUniqueID, note: UInt8, pressure: UInt32) {
    synth?.polyphonicKeyPressure(note: note, pressure: pressure.b0)
  }

  public func controlChange(source: MIDIUniqueID, controller: UInt8, value: UInt8) {
    os_log(.debug, log: log, "controlCHange: %d - %d", controller, value)

    let midiControllerIndex = Int(controller)
    midiControllerState[midiControllerIndex].lastValue = value
    activityNotifier.showActivity(source: source, controller: controller)

    if midiControllerState[midiControllerIndex].allowed {
      if MIDICC(rawValue: value) == .favoriteSelect {
        synth?.programChange(program: value)
      } else {
        synth?.controlChange(controller: controller, value: value)
      }
    }
  }

  public func controlChange2(source: MIDIUniqueID, controller: UInt8, value: UInt32) {
    synth?.controlChange(controller: controller, value: value.b0)
    os_log(.debug, log: log, "controlCHange: %d - %d", controller, value)
  }

  public func programChange(source: MIDIUniqueID, program: UInt8) {
    synth?.programChange(program: program)
    os_log(.debug, log: log, "programChange: %d", program)
  }

  public func programChange2(source: MIDIUniqueID, program: UInt8, bank: UInt16) {
    synth?.programChange(program: program)
    os_log(.debug, log: log, "programChange: %d", program)
  }

  public func channelPressure(source: MIDIUniqueID, pressure: UInt8) {
    synth?.channelPressure(pressure: pressure)
  }

  public func channelPressure2(source: MIDIUniqueID, pressure: UInt32) {
    synth?.channelPressure(pressure: pressure.b0)
  }

  public func pitchBendChange(source: MIDIUniqueID, value: UInt16) {
    synth?.pitchBendChange(value: value)
    os_log(.debug, log: log, "pitchBendChange: %d", value)
  }

  public func pitchBendChange2(source: MIDIUniqueID, value: UInt32) {
    synth?.pitchBendChange(value: value.w0 & 0x7FFF)
  }

  public func systemReset(source: MIDIUniqueID) {
    synth?.stopAllNotes()
  }

  public func timeCodeQuarterFrame(source: MIDIUniqueID, value: UInt8) {}
  public func songPositionPointer(source: MIDIUniqueID, value: UInt16) {}
  public func songSelect(source: MIDIUniqueID, value: UInt8) {}
  public func tuneRequest(source: MIDIUniqueID) {}
  public func timingClock(source: MIDIUniqueID) {}
  public func startCurrentSequence(source: MIDIUniqueID) {}
  public func continueCurrentSequence(source: MIDIUniqueID) {}
  public func stopCurrentSequence(source: MIDIUniqueID) {}
  public func activeSensing(source: MIDIUniqueID) {}

  // MIDI v2
  public func perNotePitchBendChange(source: MIDIUniqueID, note: UInt8, value: UInt32) {}
  public func registeredPerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32) {}
  public func assignablePerNoteControllerChange(source: MIDIUniqueID, note: UInt8, controller: UInt8, value: UInt32) {}
  public func registeredControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32) {}
  public func assignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: UInt32) {}
  public func relativeRegisteredControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32) {}
  public func relativeAssignableControllerChange(source: MIDIUniqueID, controller: UInt16, value: Int32) {}
  public func perNoteManagement(source: MIDIUniqueID, note: UInt8, detach: Bool, reset: Bool) {}
}

private final class ActivityNotifier: NSObject {

  private let notification = TypedNotification<MIDIReceiver.Payload>(name: "Activity")
  private let serialQueue = DispatchQueue(label: "MIDIReceiver.Activity", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))

  public func addMonitor(block: @escaping (MIDIReceiver.Payload) -> Void) -> NotificationObserver {
    notification.registerOnMain(block: block)
  }

  public func showActivity(source: MIDIUniqueID, controller: UInt8) {
    serialQueue.async { self.notification.post(value: .init(source: source, controller: controller)) }
  }
}
