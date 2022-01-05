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
  private let activePresetManager: ActivePresetManager
  private let sampler: Sampler
  private let wrapped: AUAudioUnit
  private let settings: Settings
  private let kernel: KernelAdapter
  
  private var currentPresetObserver: NSKeyValueObservation?
  private var activePresetSubscriberToken: SubscriberToken?

  private var _audioUnitName: String?
  private var _audioUnitShortName: String?

  private var _currentPreset: AUAudioUnitPreset?
  private var _needLoad = true

  /**
   Construct a new AUv3 component.

   - parameter componentDescription: the definition used when locating the component to create
   - parameter sampler: the Sampler instance to use for actually rendering audio
   - parameter activePresetManager: the manager of the active preset
   - parameter settings: the repository of user settings
   */
  public init(componentDescription: AudioComponentDescription, sampler: Sampler,
              activePresetManager: ActivePresetManager, settings: Settings) throws {
    let log = Logging.logger("SoundFontsAU")
    self.log = log
    self.activePresetManager = activePresetManager
    self.sampler = sampler
    self.settings = settings

    os_log(.info, log: log, "init - flags: %d man: %d type: sub: %d", componentDescription.componentFlags,
           componentDescription.componentManufacturer, componentDescription.componentType,
           componentDescription.componentSubType)
    os_log(.info, log: log, "starting AVAudioUnitSampler")

    switch sampler.start() {
    case let .success(auSampler):
      guard
        let auSampler = auSampler
      else {
        throw SoundFontsAUFailure.unableToStart
      }
      self.wrapped = auSampler.auAudioUnit

    case .failure(let what):
      os_log(.info, log: log, "failed to start sampler - %{public}s", what.localizedDescription)
      throw what
    }

    self.kernel = KernelAdapter("SoundFontsAU", wrapped: self.wrapped)

    os_log(.info, log: log, "super.init")
    do {
      try super.init(componentDescription: componentDescription, options: [])
    } catch {
      os_log(
        .info, log: log, "failed to initialize AUAudioUnit - %{public}s", error.localizedDescription
      )
      throw error
    }

    self.currentPresetObserver = wrapped.observe(\.currentPreset, options: [.new]) { [weak self] _, change in
      guard let self = self, let newValue = change.newValue else { return }
      self.currentPresetChanged(newValue)
    }

    self.activePresetSubscriberToken = activePresetManager.subscribe(self, notifier: self.activePresetChanged(_:))
    useActivePreset()

    os_log(.info, log: log, "init - done")
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
    switch event {
    case .active:
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
      os_log(.info, log: log, "audioUnitName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitName")
      _audioUnitName = newValue
      didChangeValue(forKey: "audioUnitName")
    }
  }

  override public var audioUnitShortName: String? {
    get { _audioUnitShortName }
    set {
      os_log(.info, log: log, "audioUnitShortName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitShortName")
      _audioUnitShortName = newValue
      didChangeValue(forKey: "audioUnitShortName")
    }
  }

  override public func supportedViewConfigurations(_ viewConfigs: [AUAudioUnitViewConfiguration]) -> IndexSet {
    os_log(.info, log: log, "supportedViewConfigurations")
    let indices = viewConfigs.enumerated().compactMap {
      $0.1.height > 270 ? $0.0 : nil
    }
    os_log(.info, log: log, "indices: %{public}s", indices.debugDescription)
    return IndexSet(indices)
  }

  override public var component: AudioComponent { wrapped.component }

  override public func allocateRenderResources() throws {
    os_log(.info, log: log, "allocateRenderResources BEGIN - outputBusses: %{public}d", outputBusses.count)
    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }
    do {
      try wrapped.allocateRenderResources()
      reloadActivePreset()
    } catch {
      os_log(.error, log: log, "allocateRenderResources failed - %{public}s", error.localizedDescription)
      throw error
    }
    os_log(.info, log: log, "allocateRenderResources END")
  }

  override public func deallocateRenderResources() {
    os_log(.info, log: log, "deallocateRenderResources")
    wrapped.deallocateRenderResources()
  }

  override public var renderResourcesAllocated: Bool {
    os_log(.info, log: log, "renderResourcesAllocated - %d", wrapped.renderResourcesAllocated)
    return wrapped.renderResourcesAllocated
  }

  override public func reset() {
    os_log(.info, log: log, "reset BEGIN - %d", renderResourcesAllocated)
    wrapped.reset()
    os_log(.info, log: log, "reset END")
  }

  private func reloadActivePreset() {
    os_log(.info, log: log, "reloadActivePreset BEGIN")
    guard let activePreset = activePresetManager.activePreset,
          let soundFont = activePresetManager.activeSoundFont
    else {
      os_log(.info, log: log, "reloadActivePreset END - no active preset")
      return
    }

    do {

      // This is a hack but it seems necessary to do if the host the AudioUnit is rendering. Cause the AudioUnit to just
      // emit zeros until `setBypass(false)` below.
      self.kernel.setBypass(true)
      os_log(.info, log: log, "reloadActivePreset - before loadSoundBankInstrument")
      try sampler.auSampler?.loadSoundBankInstrument(at: soundFont.fileURL,
                                                     program: UInt8(activePreset.program),
                                                     bankMSB: UInt8(activePreset.bankMSB),
                                                     bankLSB: UInt8(activePreset.bankLSB))
      os_log(.info, log: log, "reloadActivePreset - after loadSoundBankInstrument")
    } catch {
      os_log(.error, log: log, "failed loadSoundBankInstrument - %{public}s", error.localizedDescription)
    }

    // This is an inherent *flaky* hack. We don't immediately reenable rendering with the AudioUnit.
    DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.future(0.2)) {
      self.kernel.setBypass(false)
    }

    os_log(.info, log: log, "reloadActivePreset END")
  }

  private func loadActivePreset() {
    os_log(.info, log: log, "loadActivePreset BEGIN")
    guard activePresetManager.activeSoundFont != nil && activePresetManager.activePreset != nil
    else {
      os_log(.info, log: log, "loadActivePreset - nil activeSoundFont and/or activePreset")
      os_log(.info, log: log, "loadActivePreset END")
      return
    }

    os_log(.info, log: log, "loadActivePreset - calling loadActivePreset")
    self.kernel.setBypass(true)
    let result = sampler.loadActivePreset {
      os_log(.info, log: self.log, "loadActivePreset - called loadActivePreset")
      DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.future(0.1)) {
        self.kernel.setBypass(false)
      }
    }
    switch result {
    case .success: os_log(.info, log: log, "loadActivePreset - OK")
    case .failure(let error): os_log(.fault, log: log, "loadActivePreset - FAILED: %{public}s",
                                     error.localizedDescription)
    }
    os_log(.info, log: log, "loadActivePreset END")
  }

  override public var inputBusses: AUAudioUnitBusArray {
    os_log(.info, log: self.log, "inputBusses - %d", wrapped.inputBusses.count)
    return wrapped.inputBusses
  }

  override public var outputBusses: AUAudioUnitBusArray {
    os_log(.info, log: self.log, "outputBusses - %d", wrapped.outputBusses.count)
    return wrapped.outputBusses
  }

  override public var scheduleParameterBlock: AUScheduleParameterBlock {
    os_log(.info, log: self.log, "scheduleParameterBlock")
    return wrapped.scheduleParameterBlock
  }

  override public func token(byAddingRenderObserver observer: @escaping AURenderObserver) -> Int {
    os_log(.info, log: self.log, "token by AddingRenderObserver")
    return wrapped.token(byAddingRenderObserver: observer)
  }

  override public func removeRenderObserver(_ token: Int) {
    os_log(.info, log: self.log, "removeRenderObserver")
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
    os_log(.info, log: self.log, "virtualMIDICableCount - %d", wrapped.virtualMIDICableCount)
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
      os_log(.info, log: log, "fullState GET")
      var state = [String: Any]()
      addInstanceSettings(into: &state)
      return state
    }
    set {
      os_log(.info, log: log, "fullState SET")
      if let state = newValue {
        restoreInstanceSettings(from: state)
      }
    }
  }

  override public var fullStateForDocument: [String: Any]? {
    get {
      os_log(.info, log: log, "fullStateForDocument GET")
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
      os_log(.info, log: log, "fullStateForDocument SET")
      fullState = newValue
    }
  }

  /**
   Save into a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage to hold the settings
   */
  private func addInstanceSettings(into state: inout [String: Any]) {
    os_log(.info, log: log, "addInstanceSettings BEGIN")

    if let dict = self.activePresetManager.active.encodeToDict() {
      state[activeSoundFontPresetKey] = dict
    }

    state[SettingKeys.activeTagKey.key] = settings.activeTagKey.uuidString
    state[SettingKeys.showingFavorites.key] = settings.showingFavorites
    state[SettingKeys.presetsWidthMultiplier.key] = settings.presetsWidthMultiplier
    state[SettingKeys.pitchBendRange.key] = settings.pitchBendRange
    os_log(.info, log: log, "addInstanceSettings END")
  }

  /**
   Restore from a state dictionary the settings that are really part of an AUv3 instance

   - parameter state: the storage that holds the settings
   */
  private func restoreInstanceSettings(from state: [String: Any]) {
    os_log(.info, log: log, "restoreInstanceSettings BEGIN")

    if let activeTagKeyString = state[SettingKeys.activeTagKey.key] as? String,
       let activeTagKey = UUID(uuidString: activeTagKeyString) {
      settings.activeTagKey = activeTagKey
    }

    settings.restore(key: SettingKeys.showingFavorites, from: state)
    settings.restore(key: SettingKeys.presetsWidthMultiplier, from: state)
    settings.restore(key: SettingKeys.pitchBendRange, from: state)

    let value: ActivePresetKind = {
      if let dict = state[activeSoundFontPresetKey] as? [String: Any],
         let value = ActivePresetKind.decodeFromDict(dict) {
        return value
      }
      if let data = state[activeSoundFontPresetKey] as? Data,
         let value = ActivePresetKind.decodeFromData(data) {
        return value
      }
      return .none
    }()

    self.activePresetManager.setActive(value)

    os_log(.info, log: log, "restoreInstanceSettings END")
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
    os_log(.info, log: log, "currentPresetChanged BEGIN - %{public}s", preset)

    // There are no factory presets (should there be?) so this only applies to user presets.
    guard preset.number < 0 else  { return }

    if #available(iOS 13.0, *) {
      guard let state = try? wrapped.presetState(for: preset) else { return }
      os_log(.info, log: log, "state: %{public}s", state.debugDescription)
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
          if let fullState = try? presetState(for: preset) {
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
    os_log(.info, log: self.log, "startHardware")
    do {
      try wrapped.startHardware()
    } catch {
      os_log(.error, log: self.log, "startHardware failed - %s", error.localizedDescription)
      throw error
    }
    os_log(.info, log: self.log, "startHardware - done")
  }

  override public func stopHardware() { wrapped.stopHardware() }

  override public var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? {
    let block = self.wrapped.scheduleMIDIEventBlock
    let log = self.log
    return { (when: AUEventSampleTime, channel: UInt8, count: Int, bytes: UnsafePointer<UInt8>) in
      os_log(
        .info, log: log,
        "scheduleMIDIEventBlock - when: %d chan: %d count: %d cmd: %d arg1: %d, arg2: %d",
        when, channel, count, bytes[0], bytes[1], bytes[2])
      block?(when, channel, count, bytes)
    }
  }

  override public var renderBlock: AURenderBlock { wrapped.renderBlock }

  override public var internalRenderBlock: AUInternalRenderBlock {
    os_log(.info, log: log, "internalRenderBlock")
    return kernel.internalRenderBlock()
  }
}
