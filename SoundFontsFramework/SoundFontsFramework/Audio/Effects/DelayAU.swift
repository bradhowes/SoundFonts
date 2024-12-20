// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation
import CoreAudioKit
import os

public final class DelayAU: AUAudioUnit {
  private let log: Logger
  private let delay = DelayEffect()
  private lazy var audioUnit = delay.audioUnit
  private lazy var wrapped = audioUnit.auAudioUnit

  private var _currentPreset: AUAudioUnitPreset?

  public enum Address: AUParameterAddress {
    case time = 1
    case feedback
    case cutoff
    case wetDryMix
  }

  public let time: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "time", name: "Time", address: Address.time.rawValue, min: 0.0, max: 2.0, unit: .seconds,
      unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil, dependentParameters: nil)
    param.value = 1.0
    return param
  }()

  public let feedback: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "feedback", name: "Feedback", address: Address.feedback.rawValue, min: -100.0, max: 100.0,
      unit: .percent, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil)
    param.value = 50.0
    return param
  }()

  public let cutoff: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "cutoff", name: "Cutoff", address: Address.cutoff.rawValue, min: 10.0, max: 20_000.0,
      unit: .hertz, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable, .flag_DisplayLogarithmic],
      valueStrings: nil, dependentParameters: nil)
    param.value = 18_000.0
    return param
  }()

  public let wetDryMix: AUParameter = {
    let param = AUParameterTree.createParameter(
      withIdentifier: "wetDryMix", name: "Mix", address: Address.wetDryMix.rawValue, min: 0.0, max: 100.0,
      unit: .percent, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable], valueStrings: nil,
      dependentParameters: nil)
    param.value = 30.0
    return param
  }()

  public init(componentDescription: AudioComponentDescription) throws {
    let log: Logger = Logging.logger("DelayAU")
    self.log = log

    do {
      try super.init(componentDescription: componentDescription, options: [])
    } catch {
      log.error("failed to initialize AUAudioUnit - \(error.localizedDescription, privacy: .public)")
      throw error
    }

    buildParameterTree()
  }

  private func buildParameterTree() {
    let parameterTree = AUParameterTree.createTree(withChildren: [time, feedback, cutoff, wetDryMix])
    self.parameterTree = parameterTree

    parameterTree.implementorValueObserver = { parameter, value in
      switch Address(rawValue: parameter.address) {
      case .time:
        self.audioUnit.delayTime = Double(value)
        self.delay.active = self.delay.active.setTime(value)
      case .feedback:
        self.audioUnit.feedback = value
        self.delay.active = self.delay.active.setFeedback(value)
      case .cutoff:
        self.audioUnit.lowPassCutoff = value
        self.delay.active = self.delay.active.setCutoff(value)
      case .wetDryMix:
        self.audioUnit.wetDryMix = value
        self.delay.active = self.delay.active.setWetDryMix(value)
      default: break
      }
    }

    parameterTree.implementorValueProvider = { parameter in
      switch Address(rawValue: parameter.address) {
      case .time: return AUValue(self.audioUnit.delayTime)
      case .feedback: return self.audioUnit.feedback
      case .cutoff: return self.audioUnit.lowPassCutoff
      case .wetDryMix: return self.audioUnit.wetDryMix
      default: return 0
      }
    }

    log.debug("init - done")
  }

  public func setConfig(_ config: DelayConfig) {
    log.debug("setConfig")
    time.setValue(config.time, originator: nil)
    feedback.setValue(config.feedback, originator: nil)
    cutoff.setValue(config.cutoff, originator: nil)
    wetDryMix.setValue(config.wetDryMix, originator: nil)
  }
}

extension DelayAU {

  public override func supportedViewConfigurations(
    _ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
    IndexSet(availableViewConfigurations.indices)
  }

  public override var component: AudioComponent { wrapped.component }

  public override func allocateRenderResources() throws {
    log.debug("allocateRenderResources - \(self.outputBusses.count)")
    for index in 0..<outputBusses.count {
      outputBusses[index].shouldAllocateBuffer = true
    }
    do {
      try wrapped.allocateRenderResources()
    } catch {
      log.error("allocateRenderResources failed - \(error.localizedDescription, privacy: .public)")
      throw error
    }
    log.debug("allocateRenderResources - done")
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
    log.debug("reset")
    wrapped.reset()
    super.reset()
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

  public override func parametersForOverview(withCount count: Int) -> [NSNumber] {
    log.debug("parametersForOverview: \(count)")
    return [NSNumber(value: wetDryMix.address)]
  }

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

  public override var fullState: [String: Any]? {
    get { delay.active.fullState }
    set {
      guard let fullState = newValue,
            let config = DelayConfig(state: fullState)
      else { return }
      delay.active = config
      time.setValue(config.time, originator: nil)
      feedback.setValue(config.feedback, originator: nil)
      cutoff.setValue(config.cutoff, originator: nil)
      wetDryMix.setValue(config.wetDryMix, originator: nil)
    }
  }

  public override var fullStateForDocument: [String: Any]? {
    get {
      var state = fullState ?? [String: Any]()
      if let preset = _currentPreset {
        state[kAUPresetNameKey] = preset.name
        state[kAUPresetNumberKey] = preset.number
      }
      state[kAUPresetDataKey] = Data()
      state[kAUPresetTypeKey] = FourCharCode("aufx")
      state[kAUPresetSubtypeKey] = FourCharCode("dlay")
      state[kAUPresetManufacturerKey] = FourCharCode("bray")
      state[kAUPresetVersionKey] = FourCharCode(67072)
      return state
    }
    set { fullState = newValue }
  }

  public override var supportsUserPresets: Bool { true }

  public override var factoryPresets: [AUAudioUnitPreset] { delay.factoryPresets }

  public override var currentPreset: AUAudioUnitPreset? {
    get { _currentPreset }
    set {
      guard let preset = newValue else {
        _currentPreset = nil
        return
      }

      if preset.number >= 0 {
        if preset.number < delay.factoryPresetConfigs.count {
          let config = delay.factoryPresetConfigs[preset.number]
          setConfig(config)
          _currentPreset = preset
        }
      } else {
        if let fullState = try? presetState(for: preset) {
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
    return { (when: AUEventSampleTime, channel: UInt8, count: Int, bytes: UnsafePointer<UInt8>) in
      block?(when, channel, count, bytes)
    }
  }

  public override var renderBlock: AURenderBlock { wrapped.renderBlock }

  public override var internalRenderBlock: AUInternalRenderBlock {

    // Local copy of values that will be used in render block. Must not dispatch or allocate memory in the block.
    let wrappedBlock = wrapped.internalRenderBlock
    let timeParameter = time
    let feedbackParameter = feedback
    let cutoffParameter = cutoff
    let wetDryMixParameter = wetDryMix

    return {(actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock) in
      var head = realtimeEventListHead
      while head != nil {
        guard let event = head?.pointee else { break }
        if event.head.eventType == .parameter {
          let address = event.parameter.parameterAddress
          let value = event.parameter.value
          switch Address(rawValue: address) {
          case .time: timeParameter.setValue(value, originator: nil)
          case .feedback: feedbackParameter.setValue(value, originator: nil)
          case .cutoff: cutoffParameter.setValue(value, originator: nil)
          case .wetDryMix: wetDryMixParameter.setValue(value, originator: nil)
          default: break
          }
        }
        head = UnsafePointer<AURenderEvent>(event.head.next)
      }
      return wrappedBlock(
        actionFlags, timestamp, frameCount, outputBusNumber, outputData, head, pullInputBlock)
    }
  }
}

public extension AUParameterTree {

  /**
   Obtain the current value of a configuration parameter.

   - parameter withAddress: the parameter to fetch
   - returns: the current value of the parameter
   */
  func parameter(withAddress: DelayAU.Address) -> AUParameter? { parameter(withAddress: withAddress.rawValue) }
}
