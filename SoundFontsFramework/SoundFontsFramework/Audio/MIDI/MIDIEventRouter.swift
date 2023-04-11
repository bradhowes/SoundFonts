// Copyright © 2020 Brad Howes. All rights reserved.

import os.log
import CoreMIDI
import MorkAndMIDI

/**
 A MIDI receiver that processes MIDI events from an external source. Shows the keys being played if given a Keyboard,
 and forwards MIDI commands to a synth.
 */
final public class MIDIEventRouter {
  private lazy var log = Logging.logger("MIDIEventRouter")

  public struct ControllerActivityPayload: CustomStringConvertible {
    public var description: String { "\(source) \(controller) \(value)" }
    let source: MIDIUniqueID
    let controller: UInt8
    let value: UInt8
  }

  public struct ActionActivityPayload: CustomStringConvertible {
    public var description: String { "\(action) \(kind) \(value)" }
    let action: MIDIControllerAction
    let kind: MIDIControllerActionKind
    let value: UInt8
  }

  private let settings: Settings

  static private let controllerActivityNotifier = ControllerActivityNotifier()

  static public func monitorControllerActivity(block: @escaping (ControllerActivityPayload) -> Void) -> NotificationObserver {
    controllerActivityNotifier.addMonitor(block: block)
  }

  static private let actionNotifier = ActionNotifier()

  static public func monitorActionActivity(block: @escaping (ActionActivityPayload) -> Void) -> NotificationObserver {
    actionNotifier.addMonitor(block: block)
  }

  private(set) var midiControllerState: [MIDIControllerState] = []

  /// Current MIDI channel to listen to for MIDI. A value of -1 means OMNI -- accept all messages
  public private(set) var channel: Int
  public private(set) var group: Int

  public var audioEngine: AudioEngine? { _audioEngine }
  public let midiControllerActionStateManager: MIDIControllerActionStateManager

  private let _audioEngine: AudioEngine?
  private let keyboard: AnyKeyboard
  private let midiConnectionMonitor: MIDIConnectionMonitor
  private var observer: NSKeyValueObservation?
  private var synth: AnyMIDISynth? { _audioEngine?.synth }

  /**
   Construct new controller for a synth and keyboard

   - parameter synth: the synth to command
   - parameter keyboard: the Keyboard to update
   */
  public init(audioEngine: AudioEngine, keyboard: AnyKeyboard, settings: Settings,
              midiConnectionMonitor: MIDIConnectionMonitor,
              midiControllerActionStateManager: MIDIControllerActionStateManager) {
    self._audioEngine = audioEngine
    self.keyboard = keyboard
    self.settings = settings
    self.midiConnectionMonitor = midiConnectionMonitor
    self.midiControllerActionStateManager = midiControllerActionStateManager
    self.channel = settings.midiChannel
    self.group = -1
    monitorMIDIChannelValue()

    midiControllerState = (0...127).map {
      MIDIControllerState(identifier: $0, allowed: controllerAllowed($0))
    }
  }

  public func stopAllNotes() {
    keyboard.releaseAllKeys()
    // synth.stopAllNotes()
  }

  private func controllerAllowedKey(for controller: Int) -> String { "controllerAllowed\(controller)" }

  private func controllerAllowed(_ controller: Int) -> Bool {
    settings.get(key: controllerAllowedKey(for: controller), defaultValue: true)
  }

  func allowedStateChanged(controller: Int, allowed: Bool) {
    settings.set(key: controllerAllowedKey(for: controller), value: allowed)
    midiControllerState[controller].allowed = allowed
    if let lastValue = midiControllerState[controller].lastValue, allowed {
      synth?.controlChange(controller: UInt8(controller), value: UInt8(lastValue))
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

extension MIDIEventRouter: Receiver {

  public func noteOff(source: MIDIUniqueID, note: UInt8, velocity: UInt8) {
    synth?.noteOff(note: note, velocity: velocity)
    keyboard.noteIsOff(note: note)
  }

  public func noteOff2(source: MIDIUniqueID, note: UInt8, velocity: UInt16, attributeType: UInt8, attributeData: UInt16) {
    noteOff(source: source, note: note, velocity: velocity.b0)
  }

  public func noteOn(source: MIDIUniqueID, note: UInt8, velocity: UInt8) {
    let connectionState = midiConnectionMonitor.connectionState(for: source)
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
    let controllerState = midiControllerState[midiControllerIndex]

    // Update with last value for display in the MIDI Controllers view
    controllerState.lastValue = Int(value)
    Self.controllerActivityNotifier.post(source: source, controller: controller, value: value)

    // If not enabled, stop processing
    guard controllerState.allowed else { return }

    // If assigned to an action, notify action handlers
    if let actions = midiControllerActionStateManager.lookup[Int(controller)] {
      for actionIndex in actions {
        let action = midiControllerActionStateManager.actions[actionIndex]
        guard let kind = action.kind else { fatalError() }
        Self.actionNotifier.post(action: action.action, kind: kind, value: value)
      }
    }

    // Hand the controller value change to the synth
    synth?.controlChange(controller: controller, value: value)
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

private final class ActionNotifier: NSObject {

  private let notification = TypedNotification<MIDIEventRouter.ActionActivityPayload>(name: .midiAction)
  private let serialQueue = DispatchQueue(label: "MIDIRouter.ActionQueue", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))

  public func addMonitor(block: @escaping (MIDIEventRouter.ActionActivityPayload) -> Void) -> NotificationObserver {
    notification.registerOnMain(block: block)
  }

  fileprivate func post(action: MIDIControllerAction, kind: MIDIControllerActionKind, value: UInt8) {
    serialQueue.async { self.notification.post(value: .init(action: action, kind: kind, value: value)) }
  }
}

private final class ControllerActivityNotifier: NSObject {

  private let notification = TypedNotification<MIDIEventRouter.ControllerActivityPayload>(name: .midiActivity)
  private let serialQueue = DispatchQueue(label: "MIDIRouter.ControllerActivityQueue", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))

  public func addMonitor(block: @escaping (MIDIEventRouter.ControllerActivityPayload) -> Void) -> NotificationObserver {
    notification.registerOnMain(block: block)
  }

  fileprivate func post(source: MIDIUniqueID, controller: UInt8, value: UInt8) {
    serialQueue.async { self.notification.post(value: .init(source: source, controller: controller, value: value)) }
  }
}
