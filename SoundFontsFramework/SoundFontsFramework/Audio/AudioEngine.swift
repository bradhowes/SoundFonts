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
  private static let log: Logger = Logging.logger("AudioEngine")
  private var log: Logger { Self.log }

  /// The notification that tuning value has changed for the sampler
  static let tuningChangedNotification = TypedNotification<Float>(name: .tuningChanged)
  /// The notification that gain value has changed for the sampler
  static let gainChangedNotification = TypedNotification<Float>(name: .gainChanged)
  /// The notification that pan value has changed for the sampler
  static let panChangedNotification = TypedNotification<Float>(name: .panChanged)
  /// The notification that pitch bend range has changed for the sampler
  static let pitchBendRangeChangedNotification = TypedNotification<UInt8>(name: .pitchBendRangeChanged)

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

    log.debug("init BEGIN")

    activePresetManager.subscribe(self) { event in
      switch event {
      case .changed: self.pendingPresetLoad()
      case .loaded: break
      }
    }

    log.debug("init END")
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
    log.debug("start BEGIN")
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

    log.debug("start END - \(result.description, privacy: .public)")
    return result
  }

  /**
   Stop the existing audio engine. NOTE: this only applies to the standalone case.
   */
  func stop() {
    log.debug("stop BEGIN")
    guard mode == .standalone else { fatalError("unexpected `stop` called on audioUnit") }

    presetChangeManager.stop()
    midi?.stop()

    if let engine = self.engine {
      log.debug("stopping engine")
      engine.stop()
      if let synth = self.synth {
        log.debug("resetting sampler")
        synth.stopAllNotes()
        log.debug("detaching sampler")
        engine.detach(synth.avAudioUnit)
        log.debug("dropping sampler")
        self._synth = nil
      }

      log.debug("resetting engine")
      engine.reset()
      log.debug("dropping engine")
      self.engine = nil
    }

    if let sampler = self.synth {
      log.debug("resetting sampler")
      sampler.stopAllNotes()
      log.debug("dropping sampler")
      self._synth = nil
    }

    log.debug("stop END")
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
    log.debug("applyPresetConfig BEGIN")

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
        log.debug("reverb preset config")
        delay.active = config
      } else if delay.active.enabled {
        log.debug("reverb disabled")
        delay.active = delay.active.setEnabled(false)
      }
    }

    if let reverb = reverbEffect, !settings.reverbGlobal {
      if let config = presetConfig.reverbConfig {
        log.debug("delay preset config")
        reverb.active = config
      } else if reverb.active.enabled {
        log.debug("delay disabled")
        reverb.active = reverb.active.setEnabled(false)
      }
    }

    log.debug("applyPresetConfig END")
  }

  /**
   Set the AVAudioUnitSampler tuning value

   - parameter value: the value to set in cents (+/- 2400)
   */
  func setTuning(_ value: Float) {
    log.debug("setTuning BEGIN - \(value)")
    synth?.synthGlobalTuning = value
    log.debug("setTuning END")
  }

  /**
   Set the AVAudioUnitSampler masterGain value

   - parameter value: the value to set
   */
  func setGain(_ value: Float) {
    log.debug("setGain BEGIN - \(value)")
    synth?.synthGain = value
    log.debug("setGain END")
  }

  /**
   Set the AVAudioUnitSampler stereoPan value

   - parameter value: the value to set
   */
  func setPan(_ value: Float) {
    log.debug("setPan BEGIN - \(value)")
    synth?.synthStereoPan = value
    log.debug("setPan END")
  }

  /**
   Set the pitch bend range for the controller input.

   - parameter value: range in semitones
   */
  func setPitchBendRange(value: UInt8) {
    log.debug("setPitchBendRange BEGIN - \(value)")
    synth?.setPitchBendRange(value: value)
    log.debug("setPitchBendRange END")
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
    log.debug("loadActivePreset BEGIN - \(self.activePresetManager.active.description, privacy: .public)")

    // Ok if the sampler is not yet available. We will apply the preset when it is
    guard let synth = _synth else {
      log.debug("no sampler yet")
      return .failure(.noSynth)
    }

    guard let soundFont = activePresetManager.activeSoundFont else {
      log.debug("activePresetManager.activeSoundFont is nil")
      return .success(synth)
    }

    guard let preset = activePresetManager.activePreset else {
      log.debug("activePresetManager.activePreset is nil")
      return .success(synth)
    }

    let presetConfig = activePresetManager.activePresetConfig

    log.debug("requesting preset change - \(self.pendingPresetChanges)")

    // pauseRendering(synth)

    presetChangeManager.change(synth: synth, url: soundFont.fileURL, preset: preset) { [weak self] result in
      guard let self = self else { return }
      log.debug("request complete - \(result.description, privacy: .public)")

      switch result {
      case .success:
        if let presetConfig = presetConfig {
          self.applyPresetConfig(presetConfig)
        }
      case .failure:
        self.activePresetManager.setActive(.none)
      }

      if let afterLoadBlock = afterLoadBlock {
        DispatchQueue.main.async { afterLoadBlock() }
      }
    }

    log.debug("loadActivePreset END")
    return .success(synth)
  }

  func makeSynth() -> AnyMIDISynth { AVAudioUnitSampler() }

  func startEngine(_ synth: AnyMIDISynth) -> StartResult {
    log.debug("creating AVAudioEngine")
    let engine = AVAudioEngine()
    self.engine = engine

    let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
    engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

    log.debug("attaching sampler")
    engine.attach(synth.avAudioUnit)

    log.debug("attaching reverb")
    guard let reverb = reverbEffect?.audioUnit else { fatalError("unexpected nil Reverb") }
    engine.attach(reverb)

    log.debug("attaching delay")
    guard let delay = delayEffect?.audioUnit else { fatalError("unexpected nil Delay") }
    engine.attach(delay)

    // Signal processing chain: Sampler -> delay -> reverb -> mixer
    engine.connect(reverb, to: engine.mainMixerNode, format: nil)
    engine.connect(delay, to: reverb, format: nil)
    engine.connect(synth.avAudioUnit, to: delay, format: nil)

    log.debug("preparing engine for start")
    engine.prepare()

    do {
      log.debug("starting engine")
      try engine.start()
    } catch let error as NSError {
      return .failure(.engineStarting(error: error))
    }

    return loadActivePreset()
  }
}
