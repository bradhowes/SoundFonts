// Copyright © 2020 Brad Howes. All rights reserved.

import os
import AVFoundation
import CoreAudioKit
import SoundFontsFramework

final class DelayAU: AUAudioUnit {
    private let log: OSLog
    private let delay: AVAudioUnitDelay
    private let wrapped: AUAudioUnit
    private lazy var parameters: AudioUnitParameters = AudioUnitParameters(parameterHandler: self)

    public init(componentDescription: AudioComponentDescription, delay: Delay) throws {
        let log = Logging.logger("DelayAU")
        self.log = log

        os_log(.info, log: log, "init - flags: %d man: %d type: sub: %d",
               componentDescription.componentFlags, componentDescription.componentManufacturer,
               componentDescription.componentType, componentDescription.componentSubType)

        self.delay = delay.audioUnit
        self.wrapped = delay.audioUnit.auAudioUnit

        do {
            try super.init(componentDescription: componentDescription, options: [])
        } catch {
            os_log(.error, log: log, "failed to initialize AUAudioUnit - %{public}s", error.localizedDescription)
            throw error
        }

        os_log(.info, log:log, "init - done")
    }
}

extension DelayAU: AUParameterHandler {

    public func set(_ parameter: AUParameter, value: AUValue) {
        switch parameter.address {
        case AudioUnitParameters.Address.time.rawValue: delay.delayTime = Double(value)
        case AudioUnitParameters.Address.feedback.rawValue: delay.feedback = value
        case AudioUnitParameters.Address.cutoff.rawValue: delay.lowPassCutoff = value
        case AudioUnitParameters.Address.wetDryMix.rawValue: delay.wetDryMix = value
        default: break
        }
    }

    public func get(_ parameter: AUParameter) -> AUValue {
        switch parameter.address {
        case AudioUnitParameters.Address.time.rawValue: return AUValue(delay.delayTime)
        case AudioUnitParameters.Address.feedback.rawValue: return delay.feedback
        case AudioUnitParameters.Address.cutoff.rawValue: return delay.lowPassCutoff
        case AudioUnitParameters.Address.wetDryMix.rawValue: return delay.wetDryMix
        default: return 0
        }
    }
}

extension DelayAU {

    override public func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
        os_log(.info, log: log, "supportedViewConfiigurations")
        let indices = availableViewConfigurations.enumerated().compactMap { $0.1.height > 120 && $0.1.width > 200 ? $0.0 : nil }
        os_log(.info, log: log, "indices: %{public}s", indices.debugDescription)
        return IndexSet(indices)
    }

    override public var component: AudioComponent { wrapped.component }

    override public func allocateRenderResources() throws {
        os_log(.info, log: log, "allocateRenderResources - %{public}d", outputBusses.count)
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

    private func dumpParameters(name: String, tree: AUParameterGroup?, level: Int) {
        let indentation = String(repeating: " ", count: level)
        os_log(.info, log: self.log, "%{public}s dumpParameters BEGIN - %{public}s", indentation, name)
        defer { os_log(.info, log: self.log, "%{public}s dumpParameters END - %{public}s", indentation, name) }
        guard let children = tree?.children else { return }
        for child in children {
            os_log(.info, log: self.log, "%{public}s parameter %{public}s", indentation, child.displayName)
            if let group = child as? AUParameterGroup {
                dumpParameters(name: group.displayName, tree: group, level: level + 1)
            }
        }
    }

    override public func parametersForOverview(withCount count: Int) -> [NSNumber] {
        os_log(.info, log: log, "parametersForOverview: %d", count)
        return [NSNumber(value: parameters.wetDryMix.address)]
    }

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

    override public var fullState: [String : Any]? {
        get {
            wrapped.fullState ?? [:]
        }
        set {
            wrapped.fullState = newValue
        }
    }

    @available(iOS 13.0, *)
    override var supportsUserPresets: Bool { true }

    override var currentPreset: AUAudioUnitPreset? {
        get { wrapped.currentPreset }
        set {
            wrapped.currentPreset = newValue
            if #available(iOS 13.0, *) {
                if let preset = newValue {
                    if let fullState = try? presetState(for: preset) {
                        self.fullState = fullState
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

    override public var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? {
        let block = self.wrapped.scheduleMIDIEventBlock
        let log = self.log
        return { (when: AUEventSampleTime, channel: UInt8, count: Int, bytes: UnsafePointer<UInt8>) in
            os_log(.info, log: log, "scheduleMIDIEventBlock - when: %d chan: %d count: %d cmd: %d arg1: %d, arg2: %d",
                   when, channel, count, bytes[0], bytes[1], bytes[2])
            block?(when, channel, count, bytes)
        }
    }

    override public var renderBlock: AURenderBlock { wrapped.renderBlock }
    override var internalRenderBlock: AUInternalRenderBlock { wrapped.internalRenderBlock }
}