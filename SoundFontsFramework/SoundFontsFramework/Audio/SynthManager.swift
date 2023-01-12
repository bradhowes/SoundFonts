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

/**
 This class uses Apple's AVAudioUnitSampler to generate audio from SF2 files.
 */
public final class SynthManager {
  private static let log = Logging.logger("Synth")
  private var log: OSLog { Self.log }

  /// The notification that tuning value has changed for the sampler
  public static let tuningChangedNotification = TypedNotification<Float>(name: .tuningChanged)

  /// The notification that gain value has changed for the sampler
  public static let gainChangedNotification = TypedNotification<Float>(name: .gainChanged)

  /// The notification that pan value has changed for the sampler
  public static let panChangedNotification = TypedNotification<Float>(name: .panChanged)

  /// The notification that pitch bend range has changed for the sampler
  public static let pitchBendRangeChangedNotification = TypedNotification<UInt8>(name: .pitchBendRangeChanged)

  public typealias StartResult = Result<AnyMIDISynth, SynthStartFailure>

  /// The `Sampler` can run in a standalone app or as an AUv3 app extension. This is set at start and cannot be changed.
  public enum Mode {
    case standalone
    case audioUnit
  }

  /// The internal AVAudioUnitSampler that does the actual sound generation
  public private(set) var synth: AnyMIDISynth?
  public var avAudioUnit: AVAudioUnitMIDIInstrument? { synth?.avAudioUnit }
  private var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }

  public let reverbEffect: ReverbEffect?
  public let delayEffect: DelayEffect?

  private let mode: Mode
  private let activePresetManager: ActivePresetManager

  private let presetChangeManager = PresetChangeManager()
  private let settings: Settings

  private var engine: AVAudioEngine?
  private var presetLoaded: Bool = false
  private var pendingPresetChanges: Int = 0
  private var isRendering: Bool { presetLoaded && pendingPresetChanges == 0 } // engine.isRunning ?

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
              settings: Settings) {
    os_log(.debug, log: Self.log, "init BEGIN")

    self.mode = mode
    self.activePresetManager = activePresetManager
    self.reverbEffect = reverb
    self.delayEffect = delay
    self.settings = settings

    if mode == .standalone {
      precondition(reverb != nil, "unexpected nil for reverb")
      precondition(delay != nil, "unexpected nil for delay")
    }

    activePresetConfigChangedNotifier = PresetConfig.changedNotification.registerOnAny(block: applyPresetConfig(_:))
    tuningChangedNotifier = Self.tuningChangedNotification.registerOnAny(block: setTuning(_:))
    gainChangedNotifier = Self.gainChangedNotification.registerOnAny(block: setGain(_:))
    panChangedNotifier = Self.panChangedNotification.registerOnAny(block: setPan(_:))
    pitchBendRangeChangedNotifier = Self.pitchBendRangeChangedNotification.registerOnAny(block: setPitchBendRange)

    os_log(.debug, log: Self.log, "init END")
  }

  /**
   Create a new AVAudioUnitSampler to use and initialize it according to the `mode`.

   - returns: Result value indicating success or failure
   */
  public func start() -> StartResult {
    os_log(.debug, log: log, "start BEGIN")
    let synth = makeSynth()
    self.synth = synth

    if settings.globalTuningEnabled {
      synth.synthGlobalTuning = settings.globalTuning
    }

    presetChangeManager.start()

    if mode == .audioUnit {
      return .success(synth)
    }

    let result = startEngine(synth)
    os_log(.debug, log: log, "start END - %{public}s", result.description)

    return result
  }

  private func makeSynth() -> AnyMIDISynth {
#if USE_SF2ENGINE_SYNTH
    return AVSF2Engine()
#else
    return AVAudioUnitSampler()
#endif
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
      if let synth = self.synth {
        os_log(.debug, log: log, "resetting sampler")
        synth.reset()
        os_log(.debug, log: log, "detaching sampler")
        engine.detach(synth.avAudioUnit)
        os_log(.debug, log: log, "dropping sampler")
        self.synth = nil
      }

      os_log(.debug, log: log, "resetting engine")
      engine.reset()
      os_log(.debug, log: log, "dropping engine")
      self.engine = nil
    }

    if let sampler = self.synth {
      os_log(.debug, log: log, "resetting sampler")
      sampler.reset()
      os_log(.debug, log: log, "dropping sampler")
      self.synth = nil
    }

    os_log(.debug, log: log, "stop END")
  }

  /**
   Ask the sampler to use the active preset held by the ActivePresetManager.

   - parameter afterLoadBlock: callback to invoke after the load is successfully done

   - returns: Result indicating success or failure
   */
  public func loadActivePreset(_ afterLoadBlock: (() -> Void)? = nil) -> StartResult {
    os_log(.debug, log: log, "loadActivePreset BEGIN - %{public}s", activePresetManager.active.description)

    // Ok if the sampler is not yet available. We will apply the preset when it is
    guard let synth = synth else {
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

    os_log(.debug, log: log, "requesting preset change - %d", pendingPresetChanges)

    pendingPresetChanges += 1
    if pendingPresetChanges == 1 {
      engine?.pause()
    }

    presetChangeManager.change(synth: synth, url: soundFont.fileURL, preset: preset) { [weak self] result in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "request complete - %{public}s", result.description)

      if let presetConfig = presetConfig {
        self.applyPresetConfig(presetConfig)
      }

      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.presetLoaded = true
        self.pendingPresetChanges -= 1
        if self.pendingPresetChanges == 0 {
          try? self.engine?.start()
        }
        afterLoadBlock?()
      }
    }

    os_log(.debug, log: log, "loadActivePreset END")
    return .success(synth)
  }
}

extension SynthManager {

  /**
   Set the AVAudioUnitSampler tuning value

   - parameter value: the value to set in cents (+/- 2400)
   */
  public func setTuning(_ value: Float) {
    os_log(.debug, log: log, "setTuning BEGIN - %f", value)
    synth?.synthGlobalTuning = value
    os_log(.debug, log: log, "setTuning END")
  }

  /**
   Set the AVAudioUnitSampler masterGain value

   - parameter value: the value to set
   */
  public func setGain(_ value: Float) {
    os_log(.debug, log: log, "setGain BEGIN - %f", value)
    synth?.synthGain = value
    os_log(.debug, log: log, "setGain END")
  }

  /**
   Set the AVAudioUnitSampler stereoPan value

   - parameter value: the value to set
   */
  public func setPan(_ value: Float) {
    os_log(.debug, log: log, "setPan BEGIN - %f", value)
    synth?.synthStereoPan = value
    os_log(.debug, log: log, "setPan END")
  }

  /**
   Set the pitch bend range for the controller input.

   - parameter value: range in semitones
   */
  public func setPitchBendRange(value: UInt8) {
    os_log(.debug, log: log, "setPitchBendRange BEGIN - %d", value)
    guard value < 25 else {
      os_log(.error, log: log, "setPitchBendRange END - invalid value: %d", value)
      return
    }

    synth?.processMIDIEvent(status: 0xB0, data1: 101, data2: 0)
    synth?.processMIDIEvent(status: 0xB0, data1: 100, data2: 0)
    synth?.processMIDIEvent(status: 0xB0, data1: 6, data2: UInt8(value))
    synth?.processMIDIEvent(status: 0xB0, data1: 38, data2: 0)

    os_log(.debug, log: log, "setPitchBendRange END")
  }
}

extension SynthManager: KeyboardNoteProcessor {

  /**
   Start playing a sound at the given pitch. If given velocity is 0, then stop playing the note.

   - parameter midiValue: MIDI value that indicates the pitch to play
   - parameter velocity: how loud to play the note (1-127)
   */
  public func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    os_log(.debug, log: log, "startNote - %d %d", note, velocity)
    guard velocity > 0 else {
      stopNote(note: note, velocity: velocity, channel: channel)
      return
    }

    guard isRendering else { return }
    synth?.startNote(note: note, velocity: velocity, channel: channel)
  }

  /**
   Stop playing a sound at the given pitch.

   - parameter midiValue: MIDI value that indicates the pitch to stop
   */
  public func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
    os_log(.debug, log: log, "stopNote - %d %d", note, pendingPresetChanges)
    guard isRendering else { return }
    synth?.stopNote(note: note, velocity: velocity, channel: channel)
  }
}

extension SynthManager: AnyMIDIReceiver {

  public func stopAllNotes() {
    synth?.stopAllNotes()
  }

  public func changeProgram(program: UInt8, channel: UInt8) {}

  public func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {}

  public func processMIDIEvent(status: UInt8, data1: UInt8) {}

  public func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {}

  /**
   After-touch for the given playing note.

   - parameter midiValue: MIDI value that indicates the pitch being played
   - parameter pressure: the after-touch pressure value for the key
   */
  public func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {
    os_log(.debug, log: log, "setKeyPressure - %d %d", note, pressure)
    guard isRendering else { return }
    synth?.setNotePressure(note: note, pressure: pressure, channel: channel)
  }

  /**
   After-touch for the whole channel.

   - parameter pressure: the after-touch pressure value for all of the playing keys
   */
  public func setPressure(pressure: UInt8, channel: UInt8) {
    os_log(.debug, log: log, "setPressure - %d", pressure)
    guard isRendering else { return }
    synth?.setPressure(pressure: pressure, channel: channel)
  }

  /**
   Pitch-bend controller value.

   - parameter value: the controller value. Middle is 0x200
   */
  public func setPitchBend(value: UInt16, channel: UInt8) {
    os_log(.debug, log: log, "setPitchBend - %d", value)
    guard isRendering else { return }
    synth?.setPitchBend(value: value, channel: channel)
  }

  public func setController(controller: UInt8, value: UInt8, channel: UInt8) {
    os_log(.debug, log: log, "setController - %d %d", controller, value)
    guard isRendering else { return }
    synth?.setController(controller: controller, value: value, channel: channel)
  }
}

extension SynthManager {

  private func startEngine(_ synth: AnyMIDISynth) -> StartResult {

    os_log(.debug, log: log, "creating AVAudioEngine")
    let engine = AVAudioEngine()
    self.engine = engine

    let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
    engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

    os_log(.debug, log: log, "attaching sampler")
    engine.attach(synth.avAudioUnit)

    os_log(.debug, log: log, "attaching reverb")
    guard let reverb = reverbEffect?.audioUnit else { fatalError("unexpected nil Reverb") }
    engine.attach(reverb)

    os_log(.debug, log: log, "attaching delay")
    guard let delay = delayEffect?.audioUnit else { fatalError("unexpected nil Delay") }
    engine.attach(delay)

    // Signal processing chain: Sampler -> delay -> reverb -> mixer
    engine.connect(reverb, to: engine.mainMixerNode, format: nil)
    engine.connect(delay, to: reverb, format: nil)
    engine.connect(synth.avAudioUnit, to: delay, format: nil)

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
      setPitchBendRange(value: UInt8(pitchBendRange))
    } else {
      setPitchBendRange(value: UInt8(settings.pitchBendRange))
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
