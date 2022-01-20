// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox
import SoundFontsFramework
import CoreAudioKit
import os

/**
 AUv3 component for SoundFonts. The component hosts its own Sampler instance but unlike the SoundFonts app, it does
 not contain reverb or delay effects. Most of the methods and getters forward to a _wrapped_ AUAudioUnit, the one that
 comes from the AVAudioUnitSampler.
 */
final class SoundFontsAU: AUAudioUnit {
  private let log: OSLog
  private let sampler: Sampler
  private let identity: Int
  private let activePresetManager: ActivePresetManager
  private let settings: Settings
  private let wrapped: AUAudioUnit

  private var currentPresetObserver: NSKeyValueObservation?
  private var activePresetSubscriberToken: SubscriberToken?

  private var _audioUnitName: String?
  private var _audioUnitShortName: String?
  private var _currentPreset: AUAudioUnitPreset?

  /// Maximum frames to render
  private let maxFramesToRender: UInt32 = 512

  /**
   Construct a new AUv3 component.

   - parameter componentDescription: the definition used when locating the component to create
   - parameter sampler: the Sampler instance to use for actually rendering audio
   - parameter identity: the (pseudo) unique identity for this instance
   - parameter activePresetManager: the manager of the active preset
   - parameter settings: the repository of user settings
   */
  public init(componentDescription: AudioComponentDescription, sampler: Sampler, identity: Int,
              activePresetManager: ActivePresetManager, settings: Settings) throws {
    let log = Logging.logger("SoundFontsAU[\(identity)]")
    self.log = log
    self.sampler = sampler
    self.identity = identity
    self.activePresetManager = activePresetManager
    self.settings = settings

    os_log(.debug, log: log, "init - flags: %d man: %d type: sub: %d", componentDescription.componentFlags,
           componentDescription.componentManufacturer, componentDescription.componentType,
           componentDescription.componentSubType)
    os_log(.debug, log: log, "starting AVAudioUnitSampler")

    switch sampler.start() {
    case let .success(auSampler): self.wrapped = auSampler.auAudioUnit
    case .failure(let what):
      os_log(.debug, log: log, "failed to start sampler - %{public}s", what.localizedDescription)
      throw what
    }

    os_log(.debug, log: log, "super.init")
    do {
      try super.init(componentDescription: componentDescription, options: [])
    } catch {
      os_log(
        .debug, log: log, "failed to initialize AUAudioUnit - %{public}s", error.localizedDescription
      )
      throw error
    }

    maximumFramesToRender = maxFramesToRender
    activePresetSubscriberToken = activePresetManager.subscribe(self, notifier: self.activePresetChanged(_:))
    useActivePreset()

    os_log(.debug, log: log, "init - done")
  }

  deinit {
    self.currentPresetObserver?.invalidate()
  }
}


extension SoundFontsAU {

  /**
   Notification that the active preset in the UI has changed. Update the short name of the component to show the preset
   name.

   - parameter event: the event that happened
   */
  private func activePresetChanged(_ event: ActivePresetEvent) {
    os_log(.debug, log: log, "activePresetChanged BEGIN - %{public}s", event.description)
    switch event {
    case .change:
      self.currentPreset = nil
      useActivePreset()
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

  override public var audioUnitName: String? {
    get { _audioUnitName }
    set {
      os_log(.debug, log: log, "audioUnitName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitName")
      _audioUnitName = newValue
      didChangeValue(forKey: "audioUnitName")
    }
  }

  override public var audioUnitShortName: String? {
    get { _audioUnitShortName }
    set {
      os_log(.debug, log: log, "audioUnitShortName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitShortName")
      _audioUnitShortName = newValue
      didChangeValue(forKey: "audioUnitShortName")
    }
  }

  override public func supportedViewConfigurations(_ viewConfigs: [AUAudioUnitViewConfiguration]) -> IndexSet {
    os_log(.debug, log: log, "supportedViewConfigurations")
    let indices = viewConfigs.enumerated().compactMap {
      $0.1.height > 270 ? $0.0 : nil
    }
    os_log(.debug, log: log, "indices: %{public}s", indices.debugDescription)
    return IndexSet(indices)
  }

  override public var component: AudioComponent { wrapped.component }

  override public func allocateRenderResources() throws {
    os_log(.debug, log: log, "allocateRenderResources BEGIN - outputBusses: %{public}d", outputBusses.count)
    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }

    do {
      try wrapped.allocateRenderResources()
    } catch {
      os_log(.error, log: log, "allocateRenderResources failed - %{public}s", error.localizedDescription)
      throw error
    }

    os_log(.debug, log: log, "allocateRenderResources END")
  }

  override public func deallocateRenderResources() {
    os_log(.debug, log: log, "deallocateRenderResources")
    wrapped.deallocateRenderResources()
  }

  override public var renderResourcesAllocated: Bool {
    os_log(.debug, log: log, "renderResourcesAllocated - %d", wrapped.renderResourcesAllocated)
    return wrapped.renderResourcesAllocated
  }

  override public func reset() {
    os_log(.debug, log: log, "reset BEGIN - %d", renderResourcesAllocated)
    wrapped.reset()
    reloadActivePreset()
    os_log(.debug, log: log, "reset END")
  }

  private func reloadActivePreset() {
    os_log(.debug, log: log, "reloadActivePreset BEGIN")
    guard let activePreset = activePresetManager.activePreset,
          let soundFont = activePresetManager.activeSoundFont,
          let presetConfig = activePresetManager.activePresetConfig
    else {
      os_log(.debug, log: log, "reloadActivePreset END - no active preset")
      return
    }

    do {

      os_log(.debug, log: log, "reloadActivePreset - before loadSoundBankInstrument %{public}s", presetConfig.name)
      try sampler.auSampler?.loadSoundBankInstrument(at: soundFont.fileURL,
                                                     program: UInt8(activePreset.program),
                                                     bankMSB: UInt8(activePreset.bankMSB),
                                                     bankLSB: UInt8(activePreset.bankLSB))
      os_log(.debug, log: log, "reloadActivePreset - after loadSoundBankInstrument")
    } catch {
      os_log(.error, log: log, "failed loadSoundBankInstrument - %{public}s", error.localizedDescription)
    }

    os_log(.debug, log: self.log, "reloadActivePreset - applying preset config")
    self.sampler.applyPresetConfig(presetConfig)

    os_log(.debug, log: log, "reloadActivePreset END")
  }

  override public var inputBusses: AUAudioUnitBusArray {
    os_log(.debug, log: self.log, "inputBusses - %d", wrapped.inputBusses.count)
    return wrapped.inputBusses
  }

  override public var outputBusses: AUAudioUnitBusArray {
    os_log(.debug, log: self.log, "outputBusses - %d", wrapped.outputBusses.count)
    return wrapped.outputBusses
  }

  override public var scheduleParameterBlock: AUScheduleParameterBlock {
    os_log(.debug, log: self.log, "scheduleParameterBlock")
    return wrapped.scheduleParameterBlock
  }

  override public func token(byAddingRenderObserver observer: @escaping AURenderObserver) -> Int {
    os_log(.debug, log: self.log, "token by AddingRenderObserver")
    return wrapped.token(byAddingRenderObserver: observer)
  }

  override public func removeRenderObserver(_ token: Int) {
    os_log(.debug, log: self.log, "removeRenderObserver")
    wrapped.removeRenderObserver(token)
  }

  override public var maximumFramesToRender: AUAudioFrameCount {
    didSet { wrapped.maximumFramesToRender = self.maximumFramesToRender }
  }

  override public var parameterTree: AUParameterTree? {
    get {
      wrapped.parameterTree
    }
    set {
      wrapped.parameterTree = newValue
    }
  }

  override public func parametersForOverview(withCount count: Int) -> [NSNumber] { [] }
  override public var allParameterValues: Bool { wrapped.allParameterValues }
  override public var isMusicDeviceOrEffect: Bool { true }

  override public var virtualMIDICableCount: Int {
    os_log(.debug, log: self.log, "virtualMIDICableCount - %d", wrapped.virtualMIDICableCount)
    return wrapped.virtualMIDICableCount
  }

  override public var midiOutputNames: [String] { wrapped.midiOutputNames }

  override public var midiOutputEventBlock: AUMIDIOutputEventBlock? {
    get { wrapped.midiOutputEventBlock }
    set { wrapped.midiOutputEventBlock = newValue }
  }
}

// MARK: - State Management

extension SoundFontsAU {

  private var activeSoundFontPresetKey: String { "soundFontPatch" } // Legacy name -- do not change

  override public var fullState: [String: Any]? {
    get {
      os_log(.debug, log: log, "fullState GET")
      var state = [String: Any]()
      addInstanceSettings(into: &state)
      return state
    }
    set {
      os_log(.debug, log: log, "fullState SET")
      if let state = newValue {
        restoreInstanceSettings(from: state)
      }
    }
  }

  override public var fullStateForDocument: [String: Any]? {
    get {
      os_log(.debug, log: log, "fullStateForDocument GET")
      var state = fullState ?? [String: Any]()
      if let preset = _currentPreset {
        state[kAUPresetNameKey] = preset.name
        state[kAUPresetNumberKey] = preset.number
      }
      state[kAUPresetDataKey] = Data()
      state[kAUPresetTypeKey] = FourCharCode(stringLiteral: "aumu")
      state[kAUPresetSubtypeKey] = FourCharCode(stringLiteral: "sfnt")
      state[kAUPresetManufacturerKey] = FourCharCode(stringLiteral: "bray")
      state[kAUPresetVersionKey] = FourCharCode(67072)
      return state
    }
    set {
      os_log(.debug, log: log, "fullStateForDocument SET %{public}s", newValue.descriptionOrNil)
      if let state = newValue {
        let presetName = state[kAUPresetNameKey] as? String
        os_log(.debug, log: log, "kAUPresetNameKey '%{public}s'", presetName.descriptionOrNil)
        let presetNumber = state[kAUPresetNumberKey] as? Int
        os_log(.debug, log: log, "kAUPresetNumberKey '%d'", presetNumber ?? -1)
        let presetData = state[kAUPresetDataKey] as? Data
        os_log(.debug, log: log, "kAUPresetDataKey '%{public}s'", presetData.descriptionOrNil)
        let presetType = state[kAUPresetTypeKey] as? FourCharCode
        os_log(.debug, log: log, "kAUPresetTypeKey '%{public}s'", presetType.descriptionOrNil)
        let presetSubtype = state[kAUPresetSubtypeKey] as? FourCharCode
        os_log(.debug, log: log, "kAUPresetSubtypeKey '%{public}s'", presetSubtype.descriptionOrNil)
        let presetManufacturer = state[kAUPresetManufacturerKey] as? FourCharCode
        os_log(.debug, log: log, "kAUPresetManufacturerKey '%{public}s'", presetManufacturer.descriptionOrNil)
        let presetVersion = state[kAUPresetVersionKey] as? FourCharCode
        os_log(.debug, log: log, "kAUPresetVersionKey '%{public}s'", presetVersion.descriptionOrNil)
      }
      fullState = newValue
    }
  }

  /**
   Save into a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage to hold the settings
   */
  private func addInstanceSettings(into state: inout [String: Any]) {
    os_log(.debug, log: log, "addInstanceSettings BEGIN")

    if let dict = self.activePresetManager.active.encodeToDict() {
      state[activeSoundFontPresetKey] = dict
    }

    state[SettingKeys.activeTagKey.key] = settings.activeTagKey.uuidString
    state[SettingKeys.globalTuning.key] = settings.globalTuning
    state[SettingKeys.pitchBendRange.key] = settings.pitchBendRange
    state[SettingKeys.presetsWidthMultiplier.key] = settings.presetsWidthMultiplier
    state[SettingKeys.showingFavorites.key] = settings.showingFavorites

    os_log(.debug, log: log, "addInstanceSettings END")
  }

  /**
   Restore from a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage that holds the settings
   */
  private func restoreInstanceSettings(from state: [String: Any]) {
    os_log(.debug, log: log, "restoreInstanceSettings BEGIN")

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

    os_log(.debug, log: log, "restoreInstanceSettings END")
  }
}

// MARK: - User Presets Management

extension SoundFontsAU {

  override var supportsUserPresets: Bool { true }

  /**
   Notification that the `currentPreset` attribute of the AudioUnit has changed. These should be user presets created
   by a host application. The host can then change the current preset and we need to react to this change by updating
   the active preset value. We do this as a side-effect of setting the `fullState` attribute with the state for the
   give user preset.

   - parameter preset: the new value of `currentPreset`
   */
  private func currentPresetChanged(_ preset: AUAudioUnitPreset?) {
    guard let preset = preset else { return }
    os_log(.debug, log: log, "currentPresetChanged BEGIN - %{public}s", preset)

    // There are no factory presets (should there be?) so this only applies to user presets.
    guard preset.number < 0 else  { return }

    if #available(iOS 13.0, *) {
      guard let state = try? wrapped.presetState(for: preset) else { return }
      os_log(.debug, log: log, "state: %{public}s", state.debugDescription)
      fullState = state
    }
  }

  override var currentPreset: AUAudioUnitPreset? {
    get { _currentPreset }
    set {
      guard let preset = newValue else {
        _currentPreset = nil
        return
      }

      if preset.number < 0 {
        if #available(iOS 13.0, *) {
          if let fullState = try? wrapped.presetState(for: preset) {
            self.fullState = fullState
            _currentPreset = preset
          }
        }
      }
    }
  }

  override public var latency: TimeInterval { wrapped.latency }
  override public var tailTime: TimeInterval { wrapped.tailTime }

  override public var renderQuality: Int {
    get { wrapped.renderQuality }
    set { wrapped.renderQuality = newValue }
  }

  override public var channelCapabilities: [NSNumber]? { wrapped.channelCapabilities }

  override public var channelMap: [NSNumber]? {
    get { wrapped.channelMap }
    set { wrapped.channelMap = newValue }
  }

  override public func profileState(forCable cable: UInt8, channel: MIDIChannelNumber)
  -> MIDICIProfileState
  {
    wrapped.profileState(forCable: cable, channel: channel)
  }

  override public var canPerformInput: Bool { wrapped.canPerformInput }

  override public var canPerformOutput: Bool { wrapped.canPerformOutput }

  override public var isInputEnabled: Bool {
    get { wrapped.isInputEnabled }
    set { wrapped.isInputEnabled = newValue }
  }

  override public var isOutputEnabled: Bool {
    get { wrapped.isOutputEnabled }
    set { wrapped.isOutputEnabled = newValue }
  }

  override public var outputProvider: AURenderPullInputBlock? {
    get { wrapped.outputProvider }
    set { wrapped.outputProvider = newValue }
  }

  override public var inputHandler: AUInputHandler? {
    get { wrapped.inputHandler }
    set { wrapped.inputHandler = newValue }
  }

  override public var isRunning: Bool { wrapped.isRunning }

  override public func startHardware() throws {
    os_log(.debug, log: self.log, "startHardware")
    do {
      try wrapped.startHardware()
    } catch {
      os_log(.error, log: self.log, "startHardware failed - %s", error.localizedDescription)
      throw error
    }
    os_log(.debug, log: self.log, "startHardware - done")
  }

  override public func stopHardware() { wrapped.stopHardware() }

  override public var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? {
    let block = self.wrapped.scheduleMIDIEventBlock
    let log = self.log
    return { (when: AUEventSampleTime, channel: UInt8, count: Int, bytes: UnsafePointer<UInt8>) in
      os_log(
        .debug, log: log,
        "scheduleMIDIEventBlock - when: %d chan: %d count: %d cmd: %d arg1: %d, arg2: %d",
        when, channel, count, bytes[0], bytes[1], bytes[2])
      block?(when, channel, count, bytes)
    }
  }

  override public var renderBlock: AURenderBlock { wrapped.renderBlock }

  override public var internalRenderBlock: AUInternalRenderBlock {
    os_log(.debug, log: log, "internalRenderBlock")
    return wrapped.internalRenderBlock
  }
}
