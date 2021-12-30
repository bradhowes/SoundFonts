// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

/**
 AUv3 component for SoundFonts. The component hosts its own Sampler instance but unlike the SoundFonts app, it does not
 contain reverb or delay effects. Most of the methods and properties forward to a _wrapped_ AUAudioUnit, the one that
 comes from AVAudioUnitSampler.
 */
final class SoundFontsAU: AUAudioUnit {
  private let log: OSLog
  private let activePresetManager: ActivePresetManager
  private let sampler: Sampler
  private let wrapped: AUAudioUnit
  private var currentPresetObserver: NSKeyValueObservation!
  private let identity: Int
  private var activePresetSubscriberToken: SubscriberToken?

  private var _audioUnitName: String?
  private var _audioUnitShortName: String?

  private let _parameterTree: AUParameterTree

  /**
   Construct a new AUv3 component.

   - parameter componentDescription: the definition used when locating the component to create
   - parameter sampler: the Sampler instance to use for actually rendering audio
   - parameter activePresetManager: the manager of the active preset
   - parameter identity: the unique index for this AUv3 instance. There should not be another running instance with this
   same value.
   - parameter parameterTree: the AUParameterTree with the parameter definitions for external controls
   */
  public init(componentDescription: AudioComponentDescription, sampler: Sampler,
              activePresetManager: ActivePresetManager, identity: Int, parameterTree: AUParameterTree) throws {
    let log = Logging.logger("SoundFontsAU")
    self.log = log
    self.activePresetManager = activePresetManager
    self.sampler = sampler
    self.identity = identity
    self._parameterTree = parameterTree
    
    os_log(.info, log: log, "init - flags: %d man: %d type: sub: %d", componentDescription.componentFlags,
           componentDescription.componentManufacturer, componentDescription.componentType,
           componentDescription.componentSubType)

    os_log(.info, log: log, "starting AVAudioUnitSampler - sampler: %{public}s", String.pointer(sampler))

    switch sampler.start() {
    case let .success(auSampler):
      guard let auSampler = auSampler else { fatalError("unexpected error") }
      self.wrapped = auSampler.auAudioUnit

    case .failure(let what):
      os_log(.info, log: log, "failed to start sampler - %{public}s", what.localizedDescription)
      throw what
    }

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
      self?.currentPresetChanged(change.newValue!)
    }

    self.activePresetSubscriberToken = activePresetManager.subscribe(self, notifier: self.activePresetChanged(_:))
    self.updateShortName()

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
    self.updateShortName()
    self.currentPreset = nil
  }

  private func updateShortName() {
    let presetName = activePresetManager.activePresetConfig?.name ?? "---"
    self.audioUnitShortName = "\(presetName)"
  }
}

extension SoundFontsAU {

  /// The AVAudioUnit.audioUnitShortName
  override public var audioUnitShortName: String? {
    get { _audioUnitShortName }
    set {
      os_log(.info, log: log, "audioUnitShortName set - %{public}s", newValue ?? "???")
      willChangeValue(forKey: "audioUnitShortName")
      _audioUnitShortName = newValue
      didChangeValue(forKey: "audioUnitShortName")
    }
  }

  override public func supportedViewConfigurations(_ viewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
    os_log(.info, log: log, "supportedViewConfigurations")
    // Bit arbitrary, but don't allow for very small sizes.
    let indices = viewConfigurations.enumerated().compactMap { ($0.1.height > 270 && $0.1.width > 270) ? $0.0 : nil }
    os_log(.info, log: log, "indices: %{public}s", indices.debugDescription)
    return IndexSet(indices)
  }

  override public var component: AudioComponent { wrapped.component }

  override public func allocateRenderResources() throws {
    os_log(.info, log: log, "allocateRenderResources - outputBusses: %d", outputBusses.count)
    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }

    do {
      try wrapped.allocateRenderResources()
    } catch {
      os_log(.error, log: log, "allocateRenderResources failed - %{public}s", error.localizedDescription)
      throw error
    }

    // We need to do this since the AVAudioUnitSampler used internally by the Sampler appears to forget its current
    // settings when `deallocateRenderResources` or `reset` is called.
    _ = self.sampler.loadActivePreset()

    os_log(.info, log: log, "allocateRenderResources - done")
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
    os_log(.info, log: log, "reset")
    wrapped.reset()
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
    get { _parameterTree }
    set { fatalError("setting parameterTree is unsupported") }
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
      os_log(.info, log: log, "fullState SET")
      var state = wrapped.fullState ?? [String: Any]()
      injectActiveSoundFontPreset(into: &state)
      return state
    }
    set {
      os_log(.info, log: log, "fullState SET")
      wrapped.fullState = newValue
      if let state = newValue {
        useActiveSoundFontPreset(from: state)
      }
    }
  }

  override public var fullStateForDocument: [String: Any]? {
    get {
      os_log(.info, log: log, "fullStateForDocument GET")
      var state = wrapped.fullStateForDocument ?? [String: Any]()
      injectActiveSoundFontPreset(into: &state)
      return state
    }
    set {
      os_log(.info, log: log, "fullStateForDocument SET")
      wrapped.fullStateForDocument = newValue
      if let state = newValue {
        useActiveSoundFontPreset(from: state)
      }
    }
  }

  private func injectActiveSoundFontPreset(into state: inout [String: Any]) {
    if let dict = self.activePresetManager.active.encodeToDict() {
      os_log(.info, log: log, "injectActiveSoundFontPreset - %{public}s", dict.description)
      state[activeSoundFontPresetKey] = dict
    }
  }

  private func useActiveSoundFontPreset(from state: [String: Any]) {
    guard let dict = state[activeSoundFontPresetKey] as? [String: Any],
          let value = ActivePresetKind.decodeFromDict(dict)
    else {
      return
    }
    os_log(.info, log: log, "useActiveSoundFontPreset - %{public}s", value.description)
    self.activePresetManager.setActive(value)
  }
}

// MARK: - User Presets Management

extension SoundFontsAU {

  /// Announce that we support user presets.
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
    os_log(.info, log: log, "currentPresetChanged %{public}s", preset)

    // There are no factory presets (should there be?) so this only applies to user presets.
    guard preset.number < 0 else  { return }

    if #available(iOS 13.0, *) {
      guard let state = try? wrapped.presetState(for: preset) else { return }
      os_log(.info, log: log, "state: %{public}s", state.debugDescription)
      fullState = state
    }
  }
}

extension SoundFontsAU {

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

  override public func profileState(forCable cable: UInt8, channel: MIDIChannelNumber) -> MIDICIProfileState {
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
  override public var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? { wrapped.scheduleMIDIEventBlock }
  override public var renderBlock: AURenderBlock { wrapped.renderBlock }
  override var internalRenderBlock: AUInternalRenderBlock { wrapped.internalRenderBlock }
}
