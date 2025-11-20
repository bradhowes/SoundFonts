// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox
import AVKit
import CoreAudioKit
import os

/**
 AUv3 component for SoundFonts. The component hosts its own synth instance but unlike the SoundFonts app, it does
 not contain reverb or delay effects. Most of the methods and getters forward to a _wrapped_ AUAudioUnit, the one that
 comes from the AVAudioUnitSampler.
 */
public final class SoundFontsAU: AUAudioUnit {
  private let log: Logger
  private let audioEngine: AudioEngine

  // NOTE: this holds a random word selected using a UUID value generated for this instance. It should only be used
  // for logging and nothing more.
  private let identity: String
  private let activePresetManager: ActivePresetManager
  private let settings: Settings
  private let wrapped: AUAudioUnit

  private var activePresetSubscriberToken: SubscriberToken?

  private var _audioUnitName: String?
  private var _audioUnitShortName: String?
  private var _currentPreset: AUAudioUnitPreset?

  /// Maximum frames to render
  private let maxFramesToRender: UInt32 = 512

  /**
   Construct a new AUv3 component.

   - parameter componentDescription: the definition used when locating the component to create
   - parameter audioEngine: the Synth instance to use for actually rendering audio
   - parameter identity: the (pseudo) unique identity for this instance
   - parameter activePresetManager: the manager of the active preset
   - parameter settings: the repository of user settings
   */
  public init(componentDescription: AudioComponentDescription, audioEngine: AudioEngine, identity: String,
              activePresetManager: ActivePresetManager, settings: Settings) throws {
    let log: Logger = Logging.logger("SoundFontsAU[\(identity)]")
    self.log = log
    self.audioEngine = audioEngine
    self.identity = identity
    self.activePresetManager = activePresetManager
    self.settings = settings

    log.info("init")

    switch audioEngine.start() {
    case let .success(synth): self.wrapped = synth.avAudioUnit.auAudioUnit
    case .failure(let what):
      log.error("failed to start synth - \(what.localizedDescription, privacy: .public)")
      throw what
    }

    log.info("super.init")
    do {
      try super.init(componentDescription: componentDescription, options: [])
    } catch {
      log.debug("failed to initialize AUAudioUnit - \(error.localizedDescription, privacy: .public)")
      throw error
    }

    maximumFramesToRender = maxFramesToRender
    activePresetSubscriberToken = activePresetManager.subscribe(self, notifier: self.activePresetChanged(_:))
    useActivePreset()

    log.info("init - done")
  }
}

extension SoundFontsAU {

  /**
   Notification that the active preset in the UI has changed. Update the short name of the component to show the preset
   name.

   - parameter event: the event that happened
   */
  private func activePresetChanged(_ event: ActivePresetEvent) {
    log.debug("activePresetChanged BEGIN - \(event.description, privacy: .public)")
    switch event {
    case .changed:
      self.currentPreset = nil
      useActivePreset()
    case .loaded:
      break
    }
  }

  private func useActivePreset() {
    updateShortName()
    reloadActivePreset()
  }

  private func updateShortName() {
    let presetName = activePresetManager.activePresetConfig?.name ?? "---"
    self.audioUnitShortName = "\(presetName)"
  }
}

extension SoundFontsAU {

  public override var audioUnitName: String? {
    get { _audioUnitName }
    set {
      log.debug("audioUnitName set - \(newValue ?? "???", privacy: .public)")
      willChangeValue(forKey: "audioUnitName")
      _audioUnitName = newValue
      didChangeValue(forKey: "audioUnitName")
    }
  }

  public override var audioUnitShortName: String? {
    get { _audioUnitShortName }
    set {
      log.debug("audioUnitShortName set - \(newValue ?? "???", privacy: .public)")
      willChangeValue(forKey: "audioUnitShortName")
      _audioUnitShortName = newValue
      didChangeValue(forKey: "audioUnitShortName")
    }
  }

  public override func supportedViewConfigurations(_ viewConfigs: [AUAudioUnitViewConfiguration]) -> IndexSet {
    log.debug("supportedViewConfigurations")
    let indices = viewConfigs.enumerated().compactMap {
      $0.1.height > 270 ? $0.0 : nil
    }
    log.debug("indices: \(indices.debugDescription, privacy: .public)")
    return IndexSet(indices)
  }

  public override var component: AudioComponent { wrapped.component }

  public override func allocateRenderResources() throws {
    log.debug("allocateRenderResources BEGIN - outputBusses: \(self.outputBusses.count)")
    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }

    do {
      try wrapped.allocateRenderResources()
    } catch {
      log.error("allocateRenderResources failed - \(error.localizedDescription, privacy: .public)")
      throw error
    }

    reloadActivePreset()

    log.debug("allocateRenderResources END")
  }

  public override func deallocateRenderResources() {
    log.debug("deallocateRenderResources")
    wrapped.deallocateRenderResources()
  }

  public override var renderResourcesAllocated: Bool {
    log.debug("renderResourcesAllocated - \(self.wrapped.renderResourcesAllocated)")
    return wrapped.renderResourcesAllocated
  }

  public override func reset() {
    log.debug("reset BEGIN - \(self.renderResourcesAllocated)")
    wrapped.reset()
    reloadActivePreset()
    log.debug("reset END")
  }

  private func reloadActivePreset() {
    log.debug("reloadActivePreset BEGIN")
    guard let activePreset = activePresetManager.activePreset else {
      log.debug("reloadActivePreset END - no active preset")
      return
    }

    guard let soundFont = activePresetManager.activeSoundFont else {
      log.debug("reloadActivePreset END - no active soundFont")
      return
    }

    guard let sampler = audioEngine.avAudioUnit as? AVAudioUnitSampler else {
      log.error("reloadActivePreset END - no sampler available")
      return
    }

    let url = soundFont.fileURL
    let secured = url.startAccessingSecurityScopedResource()
    defer { if secured { url.stopAccessingSecurityScopedResource() } }

    guard FileManager.default.fileExists(atPath: url.path) else {
      log.error("reloadActivePreset - soundFont file \(url.path) does not exist")
      return
    }

    // NOTE: do this here instead of using the PresetChangeManager as we want this to run in the current thread.
    do {
      sampler.reset()
      try sampler.loadSoundBankInstrument(
        at: url,
        program: UInt8(activePreset.program),
        bankMSB: UInt8(activePreset.bankMSB),
        bankLSB: UInt8(activePreset.bankLSB)
      )
    } catch {
      log.error("reloadActivePreset - failed to load sound font: \(error)")
    }

    log.debug("reloadActivePreset END")
  }

  public override var inputBusses: AUAudioUnitBusArray {
    log.debug("inputBusses - \(self.wrapped.inputBusses.count)")
    return wrapped.inputBusses
  }

  public override var outputBusses: AUAudioUnitBusArray {
    log.debug("outputBusses - \(self.wrapped.outputBusses.count)")
    return wrapped.outputBusses
  }

  public override var scheduleParameterBlock: AUScheduleParameterBlock {
    log.debug("scheduleParameterBlock")
    return wrapped.scheduleParameterBlock
  }

  public override func token(byAddingRenderObserver observer: @escaping AURenderObserver) -> Int {
    log.debug("token by AddingRenderObserver")
    return wrapped.token(byAddingRenderObserver: observer)
  }

  public override func removeRenderObserver(_ token: Int) {
    log.debug("removeRenderObserver")
    wrapped.removeRenderObserver(token)
  }

  public override var maximumFramesToRender: AUAudioFrameCount {
    didSet { wrapped.maximumFramesToRender = self.maximumFramesToRender }
  }

  public override var parameterTree: AUParameterTree? {
    get {
      wrapped.parameterTree
    }
    set {
      wrapped.parameterTree = newValue
    }
  }

  public override func parametersForOverview(withCount count: Int) -> [NSNumber] { [] }
  public override var allParameterValues: Bool { wrapped.allParameterValues }
  public override var isMusicDeviceOrEffect: Bool { true }

  public override var virtualMIDICableCount: Int {
    log.debug("virtualMIDICableCount - \(self.wrapped.virtualMIDICableCount)")
    return wrapped.virtualMIDICableCount
  }

  public override var midiOutputNames: [String] { wrapped.midiOutputNames }

  public override var midiOutputEventBlock: AUMIDIOutputEventBlock? {
    get { wrapped.midiOutputEventBlock }
    set { wrapped.midiOutputEventBlock = newValue }
  }
}

// MARK: - State Management

extension SoundFontsAU {

  private var activeSoundFontPresetKey: String { "soundFontPatch" } // Legacy name -- do not change

  public override var fullState: [String: Any]? {
    get {
      log.debug("fullState GET")
      var state = [String: Any]()
      addInstanceSettings(into: &state)
      return state
    }
    set {
      log.debug("fullState SET")
      if let state = newValue {
        restoreInstanceSettings(from: state)
      }
    }
  }

  public override var fullStateForDocument: [String: Any]? {
    get {
      log.debug("fullStateForDocument GET")
      var state = fullState ?? [String: Any]()
      if let preset = _currentPreset {
        state[kAUPresetNameKey] = preset.name
        state[kAUPresetNumberKey] = preset.number
      }
      state[kAUPresetDataKey] = Data()
      state[kAUPresetTypeKey] = FourCharCode("aumu")
      state[kAUPresetSubtypeKey] = FourCharCode("sfnt")
      state[kAUPresetManufacturerKey] = FourCharCode("bray")
      state[kAUPresetVersionKey] = FourCharCode(67072)
      return state
    }
    set {
      log.debug("fullStateForDocument SET \(newValue.descriptionOrNil, privacy: .public)")
      if let state = newValue {
        let presetName = state[kAUPresetNameKey] as? String
        log.debug("kAUPresetNameKey '\(presetName.descriptionOrNil, privacy: .public)'")
        let presetNumber = state[kAUPresetNumberKey] as? Int
        log.debug("kAUPresetNumberKey \(presetNumber ?? -1)")
        let presetData = state[kAUPresetDataKey] as? Data
        log.debug("kAUPresetDataKey '\(presetData.descriptionOrNil, privacy: .public)'")
        let presetType = state[kAUPresetTypeKey] as? FourCharCode
        log.debug("kAUPresetTypeKey '\(presetType.descriptionOrNil, privacy: .public)'")
        let presetSubtype = state[kAUPresetSubtypeKey] as? FourCharCode
        log.debug("kAUPresetSubtypeKey '\(presetSubtype.descriptionOrNil, privacy: .public)'")
        let presetManufacturer = state[kAUPresetManufacturerKey] as? FourCharCode
        log.debug("kAUPresetManufacturerKey '\(presetManufacturer.descriptionOrNil, privacy: .public)'")
        let presetVersion = state[kAUPresetVersionKey] as? FourCharCode
        log.debug("kAUPresetVersionKey '\(presetVersion.descriptionOrNil, privacy: .public)'")
      }
      fullState = newValue
    }
  }

  /**
   Save into a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage to hold the settings
   */
  private func addInstanceSettings(into state: inout [String: Any]) {
    log.debug("addInstanceSettings BEGIN")

    if let dict = self.activePresetManager.active.encodeToDict() {
      state[activeSoundFontPresetKey] = dict
    }

    state[SettingKeys.activeTagKey.key] = settings.activeTagKey.uuidString
    state[SettingKeys.globalTuning.key] = settings.globalTuning
    state[SettingKeys.pitchBendRange.key] = settings.pitchBendRange
    state[SettingKeys.presetsWidthMultiplier.key] = settings.presetsWidthMultiplier
    state[SettingKeys.showingFavorites.key] = settings.showingFavorites

    log.debug("addInstanceSettings END")
  }

  /**
   Restore from a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage that holds the settings
   */
  private func restoreInstanceSettings(from state: [String: Any]) {
    log.debug("restoreInstanceSettings BEGIN")

    settings.setAudioUnitState(state)

    let value: ActivePresetKind = {
      // First try current representation as a dict
      if let dict = state[activeSoundFontPresetKey] as? [String: Any],
         let value = ActivePresetKind.decodeFromDict(dict) {
        return value
      }
      // Fall back and try Data encoding
      if let data = state[activeSoundFontPresetKey] as? Data,
         let value = ActivePresetKind.decodeFromData(data) {
        return value
      }
      // Nothing known.
      return .none
    }()

    self.activePresetManager.restoreActive(value)

    if let activeTagKeyString = state[SettingKeys.activeTagKey.key] as? String,
       let activeTagKey = UUID(uuidString: activeTagKeyString) {
      settings.activeTagKey = activeTagKey
    }

    log.debug("restoreInstanceSettings END")
  }
}

// MARK: - User Presets Management

extension SoundFontsAU {

  public override var supportsUserPresets: Bool { true }

  /**
   Notification that the `currentPreset` attribute of the AudioUnit has changed. These should be user presets created
   by a host application. The host can then change the current preset and we need to react to this change by updating
   the active preset value. We do this as a side-effect of setting the `fullState` attribute with the state for the
   give user preset.

   - parameter preset: the new value of `currentPreset`
   */
  private func currentPresetChanged(_ preset: AUAudioUnitPreset?) {
    guard let preset = preset else { return }
    log.debug("currentPresetChanged BEGIN - \(preset, privacy: .public)")

    // There are no factory presets (should there be?) so this only applies to user presets.
    guard preset.number < 0 else { return }

    guard let state = try? wrapped.presetState(for: preset) else { return }
    log.debug("state: \(state.debugDescription, privacy: .public)")
    fullState = state
  }

  public override var currentPreset: AUAudioUnitPreset? {
    get { _currentPreset }
    set {
      guard let preset = newValue else {
        _currentPreset = nil
        return
      }

      if preset.number < 0 {
        if let fullState = try? wrapped.presetState(for: preset) {
          self.fullState = fullState
          _currentPreset = preset
        }
      }
    }
  }

  public override var latency: TimeInterval { wrapped.latency }
  public override var tailTime: TimeInterval { wrapped.tailTime }

  public override var renderQuality: Int {
    get { wrapped.renderQuality }
    set { wrapped.renderQuality = newValue }
  }

  public override var channelCapabilities: [NSNumber]? { wrapped.channelCapabilities }

  public override var channelMap: [NSNumber]? {
    get { wrapped.channelMap }
    set { wrapped.channelMap = newValue }
  }

  public override func profileState(forCable cable: UInt8, channel: MIDIChannelNumber) -> MIDICIProfileState {
    wrapped.profileState(forCable: cable, channel: channel)
  }

  public override var canPerformInput: Bool { wrapped.canPerformInput }

  public override var canPerformOutput: Bool { wrapped.canPerformOutput }

  public override var isInputEnabled: Bool {
    get { wrapped.isInputEnabled }
    set { wrapped.isInputEnabled = newValue }
  }

  public override var isOutputEnabled: Bool {
    get { wrapped.isOutputEnabled }
    set { wrapped.isOutputEnabled = newValue }
  }

  public override var outputProvider: AURenderPullInputBlock? {
    get { wrapped.outputProvider }
    set { wrapped.outputProvider = newValue }
  }

  public override var inputHandler: AUInputHandler? {
    get { wrapped.inputHandler }
    set { wrapped.inputHandler = newValue }
  }

  public override var isRunning: Bool { wrapped.isRunning }

  public override func startHardware() throws {
    log.debug("startHardware")
    do {
      try wrapped.startHardware()
    } catch {
      log.error("startHardware failed - \(error.localizedDescription, privacy: .public)")
      throw error
    }
    log.debug("startHardware - done")
  }

  public override func stopHardware() { wrapped.stopHardware() }

  public override var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? {
    let block = self.wrapped.scheduleMIDIEventBlock
    return { when, channel, count, bytes in
      block?(when, channel, count, bytes)
    }
  }

  public override var transportStateBlock: AUHostTransportStateBlock? {
    get { wrapped.transportStateBlock }
    set { wrapped.transportStateBlock = newValue }
  }

  public override var renderBlock: AURenderBlock { wrapped.renderBlock }

  // public override var internalRenderBlock: AUInternalRenderBlock { return wrapped.internalRenderBlock }

  public override var internalRenderBlock: AUInternalRenderBlock {
    let log = self.log
    let block = self.wrapped.internalRenderBlock
    let tsb = self.wrapped.transportStateBlock
    let smeb = self.wrapped.scheduleMIDIEventBlock
    var moving = false
    var zap = 0

    return {flags, when, frameCount, bus, audioBufferList, realtimeEventListHead, pullInput in
      let err = block(flags, when, frameCount, bus, audioBufferList, realtimeEventListHead, pullInput)

      // Track transitions in the transport head. When it stops, set up a counter to clear out the audio buffer
      // for a short amount of time to remove audio artifacts in Cubasis. This is a hack.
      var tsbFlags = AUHostTransportStateFlags(rawValue: 0)
      if let tsb,
         tsb(&tsbFlags, nil, nil, nil) {
        if tsbFlags.contains(.changed) {
          if tsbFlags.contains(.moving) {
            log.debug("moving")
            moving = true
          } else if moving {
            log.debug("stopped")
            moving = false
            zap = 6
            if let smeb {
              let allSoundOff: [UInt8] = [176, 120, 0]
              allSoundOff.withUnsafeBufferPointer { ptr in
                if let ptr = ptr.baseAddress {
                  log.debug("allSoundOff")
                  smeb(AUEventSampleTimeImmediate, 0, 3, ptr)
                }
              }
              let allNotesOff: [UInt8] = [176, 123, 0]
              allNotesOff.withUnsafeBufferPointer { ptr in
                if let ptr = ptr.baseAddress {
                  log.debug("allNotesOff")
                  smeb(AUEventSampleTimeImmediate, 0, 3, ptr)
                }
              }
            }
          }
        }
      }

      if zap > 0 {
        zap -= 1
        let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
        for buffer in abl {
          memset(buffer.mData, 0, Int(buffer.mDataByteSize))
        }
      }

      return err
    }
  }
}
