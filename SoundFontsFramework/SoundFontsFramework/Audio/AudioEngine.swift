// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import AudioToolbox
import Foundation
import os
import SoundFontInfoLib
import MorkAndMIDI

public protocol SynthProvider {
  var synth: AnyMIDISynth? {get}
}

/**
 This class manages the actual synth.
 */
public final class AudioEngine: SynthProvider {
  private static let log = Logging.logger("AudioEngine")
  private var log: OSLog { Self.log }

  /// The notification that tuning value has changed for the sampler
  static let tuningChangedNotification = TypedNotification<Float>(name: .tuningChanged)
  /// The notification that gain value has changed for the sampler
  static let gainChangedNotification = TypedNotification<Float>(name: .gainChanged)
  /// The notification that pan value has changed for the sampler
  static let panChangedNotification = TypedNotification<Float>(name: .panChanged)
  /// The notification that pitch bend range has changed for the sampler
  static let pitchBendRangeChangedNotification = TypedNotification<UInt8>(name: .pitchBendRangeChanged)

  static let presetLoadingChangeNotification = TypedNotification<Bool>(name: .presetLoading)

  public typealias StartResult = Result<AnyMIDISynth, SynthStartFailure>

  /// The `Sampler` can run in a standalone app or as an AUv3 app extension. This is set at start and cannot be changed.
  enum Mode {
    case standalone
    case audioUnit
  }

  /// The internal synthesizer that does the actual sound generation.
  public var synth: AnyMIDISynth? { self.pendingPresetChanges == 0 && renderingResumeTimer == nil ? _synth : nil }
  private var _synth: AnyMIDISynth?

  public var avAudioUnit: AVAudioUnitMIDIInstrument? { synth?.avAudioUnit }
  private var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }

  let reverbEffect: ReverbEffect?
  private let reverbEffectActions: ReverbEffectActions?
  let delayEffect: DelayEffect?
  private let delayEffectActions: DelayEffectActions?

  private let mode: Mode
  private let activePresetManager: ActivePresetManager
  private let settings: Settings
  public let midi: MIDI?
  private let midiControllerActionStateManager: MIDIControllerActionStateManager?

  private let presetChangeManager = PresetChangeManager()
  private var engine: AVAudioEngine?
  private var pendingPresetChanges: Int = 0
  private var renderingResumeTimer: Timer?

  private var activePresetConfigChangedNotifier: NotificationObserver?
  private var tuningChangedNotifier: NotificationObserver?
  private var gainChangedNotifier: NotificationObserver?
  private var panChangedNotifier: NotificationObserver?
  private var pitchBendRangeChangedNotifier: NotificationObserver?

  public let midiConnectionMonitor: MIDIConnectionMonitor?
  internal private(set) var midiEventRouter: MIDIEventRouter?

  private var pendingPresetLoadTimer: Timer?

  /**
   Create a new instance of a Sampler.

   In `standalone` mode, the sampler will create a `AVAudioEngine` to use to host the sampler and to generate sound.
   In `audioUnit` mode, the sampler will exist on its own and will expect an AUv3 host to provide the appropriate
   context to generate sound from its output.

   - parameter mode: determines how the sampler is hosted.
   - parameter activePresetManager: the manager of the active preset
   - parameter settings: user-adjustable settings
   */
  init(mode: Mode, activePresetManager: ActivePresetManager, settings: Settings, midi: MIDI?,
       midiControllerActionStateManager: MIDIControllerActionStateManager?) {
    os_log(.debug, log: Self.log, "init BEGIN")

    self.mode = mode
    self.activePresetManager = activePresetManager
    self.settings = settings
    self.midiControllerActionStateManager = midiControllerActionStateManager
    if mode == .standalone {
      let reverb = ReverbEffect()
      self.reverbEffect = reverb
      self.reverbEffectActions = .init(effect: reverb)
      let delay = DelayEffect()
      self.delayEffect = delay
      self.delayEffectActions = .init(effect: delay)
    } else {
      self.reverbEffect = nil
      self.reverbEffectActions = nil
      self.delayEffect = nil
      self.delayEffectActions = nil
    }

    self.midi = midi
    self.midiConnectionMonitor = midi != nil ? .init(settings: settings) : nil
    self.midi?.monitor = self.midiConnectionMonitor

    activePresetConfigChangedNotifier = PresetConfig.changedNotification.registerOnAny(block: applyPresetConfig(_:))
    tuningChangedNotifier = Self.tuningChangedNotification.registerOnAny(block: setTuning(_:))
    gainChangedNotifier = Self.gainChangedNotification.registerOnAny(block: setGain(_:))
    panChangedNotifier = Self.panChangedNotification.registerOnAny(block: setPan(_:))
    pitchBendRangeChangedNotifier = Self.pitchBendRangeChangedNotification.registerOnAny(block: setPitchBendRange)

    activePresetManager.subscribe(self) { event in
      switch event {
      case .changed: self.pendingPresetLoad()
      case .loaded: break
      }
    }

    os_log(.debug, log: Self.log, "init END")
  }
}

// MARK: - Control

public extension AudioEngine {

  func attachKeyboard(_ keyboard: AnyKeyboard) {
    guard let midi = self.midi,
          let midiConnectionMonitor = self.midiConnectionMonitor,
          let midiControllerActionStateManager = self.midiControllerActionStateManager
    else {
      fatalError("No MIDI support")
    }
    self.midiEventRouter = .init(audioEngine: self,
                                 keyboard: keyboard,
                                 settings: settings,
                                 midiConnectionMonitor: midiConnectionMonitor,
                                 midiControllerActionStateManager: midiControllerActionStateManager)
    midi.receiver = self.midiEventRouter
  }

  /**
   Create a new AVAudioUnitSampler to use and initialize it according to the `mode`.

   - returns: Result value indicating success or failure
   */
  func start() -> StartResult {
    os_log(.debug, log: log, "start BEGIN")
    let synth = makeSynth()
    self._synth = synth

    if settings.globalTuningEnabled {
      synth.synthGlobalTuning = settings.globalTuning
    }

    presetChangeManager.start()

    let result: StartResult
    switch mode {
    case .audioUnit:
      result = .success(synth)

    case .standalone:
      result = startEngine(synth)
      DispatchQueue.main.async { [weak self] in
        self?.midi?.start()
      }
    }

    os_log(.debug, log: log, "start END - %{public}s", result.description)
    return result
  }

  /**
   Stop the existing audio engine. NOTE: this only applies to the standalone case.
   */
  func stop() {
    os_log(.debug, log: log, "stop BEGIN")
    guard mode == .standalone else { fatalError("unexpected `stop` called on audioUnit") }

    presetChangeManager.stop()
    midi?.stop()

    if let engine = self.engine {
      os_log(.debug, log: log, "stopping engine")
      engine.stop()
      if let synth = self.synth {
        os_log(.debug, log: log, "resetting sampler")
        synth.stopAllNotes()
        os_log(.debug, log: log, "detaching sampler")
        engine.detach(synth.avAudioUnit)
        os_log(.debug, log: log, "dropping sampler")
        self._synth = nil
      }

      os_log(.debug, log: log, "resetting engine")
      engine.reset()
      os_log(.debug, log: log, "dropping engine")
      self.engine = nil
    }

    if let sampler = self.synth {
      os_log(.debug, log: log, "resetting sampler")
      sampler.stopAllNotes()
      os_log(.debug, log: log, "dropping sampler")
      self._synth = nil
    }

    os_log(.debug, log: log, "stop END")
  }

  /**
   Command the synth to stop playing active notes.
   */
  func stopAllNotes() { synth?.stopAllNotes()  }
}

// MARK: - Configuration Changes

private extension AudioEngine {

  /**
   Change the synth to use the given preset configuration values.

   - parameter presetConfig: the configuration to use
   */
  func applyPresetConfig(_ presetConfig: PresetConfig) {
    os_log(.debug, log: log, "applyPresetConfig BEGIN")

    if presetConfig.presetTuning != 0.0 {
      setTuning(presetConfig.presetTuning)
    } else if settings.globalTuning != 0.0 {
      setTuning(settings.globalTuning)
    } else {
      setTuning(0.0)
    }

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

  /**
   Set the AVAudioUnitSampler tuning value

   - parameter value: the value to set in cents (+/- 2400)
   */
  func setTuning(_ value: Float) {
    os_log(.debug, log: log, "setTuning BEGIN - %f", value)
    synth?.synthGlobalTuning = value
    os_log(.debug, log: log, "setTuning END")
  }

  /**
   Set the AVAudioUnitSampler masterGain value

   - parameter value: the value to set
   */
  func setGain(_ value: Float) {
    os_log(.debug, log: log, "setGain BEGIN - %f", value)
    synth?.synthGain = value
    os_log(.debug, log: log, "setGain END")
  }

  /**
   Set the AVAudioUnitSampler stereoPan value

   - parameter value: the value to set
   */
  func setPan(_ value: Float) {
    os_log(.debug, log: log, "setPan BEGIN - %f", value)
    synth?.synthStereoPan = value
    os_log(.debug, log: log, "setPan END")
  }

  /**
   Set the pitch bend range for the controller input.

   - parameter value: range in semitones
   */
  func setPitchBendRange(value: UInt8) {
    os_log(.debug, log: log, "setPitchBendRange BEGIN - %d", value)
    synth?.setPitchBendRange(value: value)
    os_log(.debug, log: log, "setPitchBendRange END")
  }

  func pauseRendering(_ synth: AnyMIDISynth) {
    pendingPresetChanges += 1
    if pendingPresetChanges == 1 {
      renderingResumeTimer?.invalidate()
      renderingResumeTimer = nil
      if let engine = self.engine {
        engine.pause()
        engine.mainMixerNode.volume = 0.0
        synth.avAudioUnit.reset()
      }
      Self.presetLoadingChangeNotification.post(value: true)
    }
  }

  func resumeRendering() {
    pendingPresetChanges -= 1
    if pendingPresetChanges == 0 {
      renderingResumeTimer = Timer.once(after: 0.3) { [weak self] _ in
        guard let self = self else { return }
        if let engine = self.engine {
          try? engine.start()
          engine.mainMixerNode.volume = 1.0
        }
        self.renderingResumeTimer = nil
        Self.presetLoadingChangeNotification.post(value: false)
      }
    }
  }

  func pendingPresetLoad() {
    // We delay changing preset in case there is another change coming over due to UI/MIDI controls. When another one
    // comes in we cancel the running timer and restart it, setting a new preset only after the time finishes and fires.
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.pendingPresetLoadTimer?.invalidate()
      self.pendingPresetLoadTimer = Timer.once(after: 0.3) { [weak self] _ in
        _ = self?.loadActivePreset()
      }
    }
  }

  /**
   Ask the sampler to use the active preset held by the ActivePresetManager.

   - parameter afterLoadBlock: callback to invoke after the load is successfully done

   - returns: StartResult indicating success or failure
   */
  func loadActivePreset(_ afterLoadBlock: (() -> Void)? = nil) -> StartResult {
    os_log(.debug, log: log, "loadActivePreset BEGIN - %{public}s", activePresetManager.active.description)

    // Ok if the sampler is not yet available. We will apply the preset when it is
    guard let synth = _synth else {
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

    let presetConfig = activePresetManager.activePresetConfig

    os_log(.debug, log: log, "requesting preset change - %d", pendingPresetChanges)

    pauseRendering(synth)

    presetChangeManager.change(synth: synth, url: soundFont.fileURL, preset: preset) { [weak self] result in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "request complete - %{public}s", result.description)

      switch result {
      case .success:
        if let presetConfig = presetConfig {
          self.applyPresetConfig(presetConfig)
        }
      case .failure:
        self.activePresetManager.setActive(.none)
      }

      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.resumeRendering()
        afterLoadBlock?()
      }
    }

    os_log(.debug, log: log, "loadActivePreset END")
    return .success(synth)
  }

  func makeSynth() -> AnyMIDISynth {
#if Dev
    if settings.useSF2Engine { return AVSF2Engine() }
#endif
#if USE_SF2ENGINE_SYNTH
    return AVSF2Engine()
#else
    return AVAudioUnitSampler()
#endif
  }

  func startEngine(_ synth: AnyMIDISynth) -> StartResult {
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
}
