// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import AudioToolbox
import Foundation
import os

import SoundFontInfoLib

/// Failure modes for a synth
public enum SynthStartFailure: Error, Equatable, CustomStringConvertible {
  /// No synth is available
  case noSynth
  /// Failed to active a session
  case sessionActivating(error: NSError)
  /// Failed to start audio engine
  case engineStarting(error: NSError)
  /// Failed to load a preset
  case presetLoading(error: NSError)
  /// The system error associated with a failure.
  var error: NSError {
    switch self {
    case .noSynth: return NSError()
    case .sessionActivating(let err): return err
    case .engineStarting(let err): return err
    case .presetLoading(let err): return err
    }
  }

  public var description: String {
    switch self {
    case .noSynth: return "<SynthStartFailure: no synth>"
    case .sessionActivating(error: let error):
      return "<SynthStartFailure: sessionActivating - \(error.localizedDescription)>"
    case .engineStarting(error: let error):
      return "<SynthStartFailure: engineStarting - \(error.localizedDescription)>"
    case .presetLoading(error: let error):
      return "<SynthStartFailure: presetLoading - \(error.localizedDescription)>"
    }
  }
}

extension Result: CustomStringConvertible {
  public var description: String {
    switch self {
    case .success(let value): return "<Result: success \(value)>"
    case .failure(let value): return "<Result: failure \(value)>"
    }
  }
}

public protocol AnyMIDISynth: PresetLoader {
  var avAudioUnit: AVAudioUnitMIDIInstrument { get }

  var globalTuning: Float { get set }
  var globalGain: Float { get set }
  var globalPan: Float { get set }

  func reset()
  func noteOn(_ note: UInt8, velocity: UInt8)
  func noteOff(_ note: UInt8)
  func changeController(_ controller: UInt8, value: UInt8)
  func pitchBend(_ value: UInt16)
  func changeAllKeysPressure(_ pressure: UInt8)
  func changeKeyPressure(_ key: UInt8, pressure: UInt8)
  func changeProgram(_ program: UInt8, bankMSB: UInt8, bankLSB: UInt8)
  func processMIDIEvent(_ midiStatus: UInt8, data1: UInt8)
  func processMIDIEvent(_ midiStatus: UInt8, data1: UInt8, data2: UInt8)
}

/**
 This class uses Apple's AVAudioUnitSampler to generate audio from SF2 files.
 */
public final class Synth {
  private static let log = Logging.logger("Synth")
  private var log: OSLog { Self.log }

  /// The notification that tuning value has changed for the sampler
  public static let tuningChangedNotification = TypedNotification<Float>(name: .tuningChanged)

  /// The notification that gain value has changed for the sampler
  public static let gainChangedNotification = TypedNotification<Float>(name: .gainChanged)

  /// The notification that pan value has changed for the sampler
  public static let panChangedNotification = TypedNotification<Float>(name: .panChanged)

  /// The notification that pitch bend range has changed for the sampler
  public static let pitchBendRangeChangedNotification = TypedNotification<Int>(name: .pitchBendRangeChanged)

  public typealias StartResult = Result<AVAudioUnitMIDIInstrument, SynthStartFailure>

  /// The `Sampler` can run in a standalone app or as an AUv3 app extension. This is set at start and cannot be changed.
  public enum Mode {
    case standalone
    case audioUnit
  }

  /// The internal AVAudioUnitSampler that does the actual sound generation
  public private(set) var avSynth: AVAudioUnitSampler?

  public let reverbEffect: ReverbEffect?
  public let delayEffect: DelayEffect?
  public let chorusEffect: ChorusEffect?

  private let mode: Mode
  private let activePresetManager: ActivePresetManager

  private let presetChangeManager = PresetChangeManager()
  private let settings: Settings

  private var engine: AVAudioEngine?
  private var presetLoaded: Bool = false

  /// Expose the underlying sampler's auAudioUnit property so that it can be used in an AudioUnit extension
  private var auAudioUnit: AUAudioUnit? { avSynth?.auAudioUnit }

  private var activePresetConfigChangedNotifier: NotificationObserver?
  private var tuningChangedNotifier: NotificationObserver?
  private var gainChangedNotifier: NotificationObserver?
  private var panChangedNotifier: NotificationObserver?
  private var pitchBendRangeChangedNotifier: NotificationObserver?

  /**
   Create a new instance of a Sampler.

   In `standalone` mode, the sampler will create a `AVAudioEngine` to use to host the sampler and to generate sound.
   In `audioUnit` mode, the sampler will exist on its own and will expect an AUv3 host to provide the appropriate
   context to generate sound from its output.

   - parameter mode: determines how the sampler is hosted.
   - parameter activePresetManager: the manager of the active preset
   - parameter reverb: the reverb effect to use along with the AVAudioUnitSampler (standalone only)
   - parameter delay: the delay effect to use along with the AVAudioUnitSampler (standalone only)
   - parameter settings: user-adjustable settings
   */
  public init(mode: Mode, activePresetManager: ActivePresetManager, reverb: ReverbEffect?, delay: DelayEffect?,
              chorus: ChorusEffect?, settings: Settings) {
    os_log(.debug, log: Self.log, "init BEGIN")

    self.mode = mode
    self.activePresetManager = activePresetManager
    self.reverbEffect = reverb
    self.delayEffect = delay
    self.chorusEffect = chorus
    self.settings = settings

    if mode == .standalone {
      precondition(reverb != nil, "unexpected nil for reverb")
      precondition(delay != nil, "unexpected nil for delay")
      // precondition(chorus != nil, "unexpected nil for chorus")
    }

    activePresetConfigChangedNotifier = PresetConfig.changedNotification.registerOnAny(block: applyPresetConfig(_:))
    tuningChangedNotifier = Self.tuningChangedNotification.registerOnAny(block: setTuning(_:))
    gainChangedNotifier = Self.gainChangedNotification.registerOnAny(block: setGain(_:))
    panChangedNotifier = Self.panChangedNotification.registerOnAny(block: setPan(_:))
    pitchBendRangeChangedNotifier = Self.pitchBendRangeChangedNotification.registerOnAny(block: setPitchBendRange(_:))

    os_log(.debug, log: Self.log, "init END")
  }

  /**
   Create a new AVAudioUnitSampler to use and initialize it according to the `mode`.

   - returns: Result value indicating success or failure
   */
  public func start() -> StartResult {
    os_log(.debug, log: log, "start BEGIN")
    let sampler = AVAudioUnitSampler()
    avSynth = sampler

    if settings.globalTuningEnabled {
      sampler.globalTuning = settings.globalTuning
    }

    presetChangeManager.start()

    if mode == .audioUnit {
      return .success(sampler)
    }

    let result = startEngine(sampler)
    os_log(.debug, log: log, "start END - %{public}s", result.description)

    return result
  }

  /**
   Stop the existing audio engine. NOTE: this only applies to the standalone case.
   */
  public func stop() {
    os_log(.debug, log: log, "stop BEGIN")
    guard mode == .standalone else { fatalError("unexpected `stop` called on audioUnit") }

    presetChangeManager.stop()

    if let engine = self.engine {
      os_log(.debug, log: log, "stopping engine")
      engine.stop()
      if let sampler = self.avSynth {
        os_log(.debug, log: log, "resetting sampler")
        sampler.reset()
        os_log(.debug, log: log, "detaching sampler")
        engine.detach(sampler)
        os_log(.debug, log: log, "dropping sampler")
        self.avSynth = nil
      }

      os_log(.debug, log: log, "resetting engine")
      engine.reset()
      os_log(.debug, log: log, "dropping engine")
      self.engine = nil
    }

    if let sampler = self.avSynth {
      os_log(.debug, log: log, "resetting sampler")
      sampler.reset()
      os_log(.debug, log: log, "dropping sampler")
      self.avSynth = nil
    }

    os_log(.debug, log: log, "stop END")
  }

  public func load(at url: URL, preset: Preset) {
    guard let synth = avSynth else { return }
    os_log(.debug, log: self.log, "load BEGIN - url: %{public}s preset: %{public}s", url.description,
           preset.description)
    presetChangeManager.change(synth: synth, url: url, preset: preset) { [weak self] result in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "load complete - %{public}s", result.description)
    }
    os_log(.debug, log: self.log, "load END")
  }

  /**
   Ask the sampler to use the active preset held by the ActivePresetManager.

   - parameter afterLoadBlock: callback to invoke after the load is successfully done

   - returns: Result indicating success or failure
   */
  public func loadActivePreset(_ afterLoadBlock: (() -> Void)? = nil) -> StartResult {
    os_log(.debug, log: log, "loadActivePreset BEGIN - %{public}s", activePresetManager.active.description)

    // Ok if the sampler is not yet available. We will apply the preset when it is
    guard let synth = avSynth else {
      os_log(.debug, log: log, "no sampler yet")
      return .failure(.noSynth)
    }

    guard let soundFont = activePresetManager.activeSoundFont else {
      os_log(.debug, log: log, "activePresetManager.activeSoundFont is nil")
      return .success(synth)
    }

    guard let preset = activePresetManager.activePreset else {
      os_log(.debug, log: log, "activePresetManager.activePreset is nil")
      return .success(synth)
    }

    self.presetLoaded = false
    let presetConfig = activePresetManager.activePresetConfig

    os_log(.debug, log: log, "requesting preset change")
    presetChangeManager.change(synth: synth, url: soundFont.fileURL, preset: preset) { [weak self] result in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "request complete - %{public}s", result.description)

      if let presetConfig = presetConfig {
        self.applyPresetConfig(presetConfig)
      }

      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.presetLoaded = true
        afterLoadBlock?()
      }
    }

    os_log(.debug, log: log, "loadActivePreset END")
    return .success(synth)
  }
}

extension Synth {

  /**
   Set the AVAudioUnitSampler tuning value

   - parameter value: the value to set in cents (+/- 2400)
   */
  public func setTuning(_ value: Float) {
    os_log(.debug, log: log, "setTuning BEGIN - %f", value)
    avSynth?.globalTuning = value
    os_log(.debug, log: log, "setTuning END")
  }

  /**
   Set the AVAudioUnitSampler masterGain value

   - parameter value: the value to set
   */
  public func setGain(_ value: Float) {
    os_log(.debug, log: log, "setGain BEGIN - %f", value)
    avSynth?.masterGain = value
    os_log(.debug, log: log, "setGain END")
  }

  /**
   Set the AVAudioUnitSampler stereoPan value

   - parameter value: the value to set
   */
  public func setPan(_ value: Float) {
    os_log(.debug, log: log, "setPan BEGIN - %f", value)
    avSynth?.stereoPan = value
    os_log(.debug, log: log, "setPan END")
  }

  /**
   Set the pitch bend range for the controller input.

   - parameter value: range in semitones
   */
  public func setPitchBendRange(_ value: Int) {
    os_log(.debug, log: log, "setPitchBendRange BEGIN - %d", value)
    guard value > 0 && value < 25 else {
      os_log(.error, log: log, "setPitchBendRange END - invalid value: %d", value)
      return
    }

    avSynth?.sendMIDIEvent(0xB0, data1: 101, data2: 0)
    avSynth?.sendMIDIEvent(0xB0, data1: 100, data2: 0)
    avSynth?.sendMIDIEvent(0xB0, data1: 6, data2: UInt8(value))
    avSynth?.sendMIDIEvent(0xB0, data1: 38, data2: 0)

    // auSampler?.sendMIDIEvent(0xB0, data1: 101, data2: 127)
    // auSampler?.sendMIDIEvent(0xB0, data1: 100, data2: 127)
    os_log(.debug, log: log, "setPitchBendRange END")
  }
}

extension Synth: NoteProcessor {

  /**
   Start playing a sound at the given pitch. If given velocity is 0, then stop playing the note.

   - parameter midiValue: MIDI value that indicates the pitch to play
   - parameter velocity: how loud to play the note (1-127)
   */
  public func noteOn(_ midiValue: UInt8, velocity: UInt8) {
    os_log(.debug, log: log, "noteOn - %d %d", midiValue, velocity)
    guard presetLoaded else {
      os_log(.error, log: log, "no preset loaded")
      return
    }
    guard velocity > 0 else {
      noteOff(midiValue)
      return
    }
    avSynth?.startNote(midiValue, withVelocity: velocity, onChannel: 0)
  }

  /**
   Stop playing a sound at the given pitch.

   - parameter midiValue: MIDI value that indicates the pitch to stop
   */
  public func noteOff(_ midiValue: UInt8) {
    os_log(.debug, log: log, "noteOff - %d", midiValue)
    guard presetLoaded else { return }
    avSynth?.stopNote(midiValue, onChannel: 0)
  }
}

extension Synth {

  /**
   After-touch for the given playing note.

   - parameter midiValue: MIDI value that indicates the pitch being played
   - parameter pressure: the after-touch pressure value for the key
   */
  public func polyphonicKeyPressure(_ midiValue: UInt8, pressure: UInt8) {
    os_log(.debug, log: log, "polyphonicKeyPressure - %d %d", midiValue, pressure)
    guard presetLoaded else { return }
    avSynth?.sendPressure(forKey: midiValue, withValue: pressure, onChannel: 0)
  }

  /**
   After-touch for the whole channel.

   - parameter pressure: the after-touch pressure value for all of the playing keys
   */
  public func channelPressure(_ pressure: UInt8) {
    os_log(.debug, log: log, "channelPressure - %d", pressure)
    guard presetLoaded else { return }
    avSynth?.sendPressure(pressure, onChannel: 0)
  }

  /**
   Pitch-bend controller value.

   - parameter value: the controller value. Middle is 0x200
   */
  public func pitchBendChange(_ value: UInt16) {
    os_log(.debug, log: log, "pitchBend - %d", value)
    guard presetLoaded else { return }
    avSynth?.sendPitchBend(value, onChannel: 0)
  }

  public func controlChange(_ controller: UInt8, value: UInt8) {
    os_log(.debug, log: log, "controllerChange - %d %d", controller, value)
    guard presetLoaded else { return }
    avSynth?.sendController(controller, withValue: value, onChannel: 0)
  }

  public func programChange(_ program: UInt8) {
    os_log(.debug, log: log, "programChange - %d", program)
    guard presetLoaded else { return }
    avSynth?.sendProgramChange(program, onChannel: 0)
  }
}

extension Synth {

  private func startEngine(_ sampler: AVAudioUnitSampler) -> StartResult {

    os_log(.debug, log: log, "creating AVAudioEngine")
    let engine = AVAudioEngine()
    self.engine = engine

    let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
    engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

    os_log(.debug, log: log, "attaching sampler")
    engine.attach(sampler)

    os_log(.debug, log: log, "attaching reverb")
    guard let reverb = reverbEffect?.audioUnit else { fatalError("unexpected nil Reverb") }
    engine.attach(reverb)

    os_log(.debug, log: log, "attaching delay")
    guard let delay = delayEffect?.audioUnit else { fatalError("unexpected nil Delay") }
    engine.attach(delay)

    // Signal processing chain: Sampler -> delay -> reverb -> mixer
    engine.connect(reverb, to: engine.mainMixerNode, format: nil)
    engine.connect(delay, to: reverb, format: nil)
    engine.connect(sampler, to: delay, format: nil)

    os_log(.debug, log: log, "preparing engine for start")
    engine.prepare()

    do {
      os_log(.debug, log: log, "starting engine")
      try engine.start()
    } catch let error as NSError {
      return .failure(.engineStarting(error: error))
    }

    return loadActivePreset()
  }

  public func applyPresetConfig(_ presetConfig: PresetConfig) {
    os_log(.debug, log: log, "applyPresetConfig BEGIN")

    let tuning: Float = {
      if presetConfig.presetTuning != 0.0 { return presetConfig.presetTuning }
      if settings.globalTuning != 0.0 { return settings.globalTuning }
      return 0.0
    }()
    setTuning(tuning)

    if let pitchBendRange = presetConfig.pitchBendRange {
      setPitchBendRange(pitchBendRange)
    } else {
      setPitchBendRange(settings.pitchBendRange)
    }

    setGain(presetConfig.gain)
    setPan(presetConfig.pan)

    // - If global mode enabled, don't change anything
    // - If preset has a config use it.
    // - Otherwise, if effect was enabled disable it
    if let delay = delayEffect, !settings.delayGlobal {
      if let config = presetConfig.delayConfig {
        os_log(.debug, log: log, "reverb preset config")
        delay.active = config
      } else if delay.active.enabled {
        os_log(.debug, log: log, "reverb disabled")
        delay.active = delay.active.setEnabled(false)
      }
    }

    if let reverb = reverbEffect, !settings.reverbGlobal {
      if let config = presetConfig.reverbConfig {
        os_log(.debug, log: log, "delay preset config")
        reverb.active = config
      } else if reverb.active.enabled {
        os_log(.debug, log: log, "delay disabled")
        reverb.active = reverb.active.setEnabled(false)
      }
    }
    os_log(.debug, log: log, "applyPresetConfig END")
  }
}
