// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation
import CoreAudioKit
import SoundFontsFramework
import os

extension String {
  fileprivate static func pointer(_ object: AnyObject?) -> String {
    guard let object = object else { return "nil" }
    let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(object).toOpaque()
    return String(describing: opaque)
  }
}

/// AUv3 component for SoundFonts. The component hosts its own Sampler instance but unlike the SoundFonts app, it does not
/// contain reverb or delay effects. Most of the methods and getters forward to another AUAudioUnit, the one that is
/// associated with the sampler.
final class SoundFontsAU: AUAudioUnit {
  private let log: OSLog
  private let activePatchManager: ActivePatchManager
  private let sampler: Sampler
  private let wrapped: AUAudioUnit

  private var _currentPreset: AUAudioUnitPreset?

  private lazy var parameters: AudioUnitParameters = AudioUnitParameters(parameterHandler: self)

  /**
     Construct a new AUv3 component.

     - parameter componentDescription: the definition used when locating the component to create
     - parameter sampler: the Sampler instance to use for actually rendering audio
     - parameter activePatchManager: the manager of the active preset/patch
     */
  public init(componentDescription: AudioComponentDescription, sampler: Sampler,
              activePatchManager: ActivePatchManager) throws {
    let log = Logging.logger("SoundFontsAU")
    self.log = log
    self.activePatchManager = activePatchManager
    self.sampler = sampler

    os_log(.info, log: log, "init - flags: %d man: %d type: sub: %d", componentDescription.componentFlags,
           componentDescription.componentManufacturer, componentDescription.componentType,
           componentDescription.componentSubType)
    os_log(.info, log: log, "starting AVAudioUnitSampler")

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

    os_log(.info, log: log, "init - done")
  }
}

extension SoundFontsAU: AUParameterHandler {

  public func set(_ parameter: AUParameter, value: AUValue) {
    switch parameter.address {
    default: break
    }
  }

  public func get(_ parameter: AUParameter) -> AUValue {
    switch parameter.address {
    default: return 0
    }
  }
}

extension SoundFontsAU {

  override public func supportedViewConfigurations(
    _ availableViewConfigurations: [AUAudioUnitViewConfiguration]
  ) -> IndexSet {
    os_log(.info, log: log, "supportedViewConfigurations")
    let indices = availableViewConfigurations.enumerated().compactMap {
      $0.1.height > 270 ? $0.0 : nil
    }
    os_log(.info, log: log, "indices: %{public}s", indices.debugDescription)
    return IndexSet(indices)
  }

  override public var component: AudioComponent { wrapped.component }

  override public func allocateRenderResources() throws {
    os_log(.info, log: log, "allocateRenderResources - outputBusses: %{public}d", outputBusses.count)
    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }
    do {
      try wrapped.allocateRenderResources()
    } catch {
      os_log(.error, log: log, "allocateRenderResources failed - %{public}s", error.localizedDescription)
      throw error
    }
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
    guard let sampler = sampler.auSampler else { return }
    guard let soundFont = activePatchManager.activeSoundFont else { return }
    guard let patch = activePatchManager.activePatch else { return }
    try? sampler.loadSoundBankInstrument(at: soundFont.fileURL, program: UInt8(patch.program),
                                         bankMSB: UInt8(patch.bankMSB), bankLSB: UInt8(patch.bankLSB))
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
      parameters.parameterTree
    }
    set {
      fatalError("setting parameterTree is unsupported")
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

  private var activeSoundFontPatchKey: String { "soundFontPatch" }

  override public var fullState: [String: Any]? {
    get {
      os_log(.info, log: log, "fullState GET")
      var fullState = [String: Any]()
      if let data = self.activePatchManager.active.encodeToData() {
        os_log(.info, log: log, "%{public}s", self.activePatchManager.active.description)
        fullState[activeSoundFontPatchKey] = data
      }
      return fullState
    }
    set {
      os_log(.info, log: log, "fullState SET")
      if let fullState = newValue {
        if let data = fullState[activeSoundFontPatchKey] as? Data {
          if let value = ActivePatchKind.decodeFromData(data) {
            os_log(.info, log: log, "%{public}s", value.description)
            self.activePatchManager.setActive(value)
          }
        }
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

  override var supportsUserPresets: Bool { true }

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
  override var internalRenderBlock: AUInternalRenderBlock { wrapped.internalRenderBlock }
}
