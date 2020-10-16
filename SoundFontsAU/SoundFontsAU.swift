// Copyright © 2020 Brad Howes. All rights reserved.

import os
import AVFoundation
import CoreAudioKit
import SoundFontsFramework

private extension String {
    static func pointer(_ object: AnyObject?) -> String {
        guard let object = object else { return "nil" }
        let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(object).toOpaque()
        return String(describing: opaque)
    }
}

final class SoundFontsAU: AUAudioUnit {
    private let log = Logging.logger("SFAU")
    private let sampler: Sampler
    private let activePatchManager: ActivePatchManager
    private let wrapped: AUAudioUnit
    private var ourParameterTree: AUParameterTree?

    enum Err: Error { case failedToStart }

    public init(componentDescription: AudioComponentDescription, sampler: Sampler, activePatchManager: ActivePatchManager) throws {
        os_log(.error, log:log, "init - flags: %d man: %d type: sub: %d",
               componentDescription.componentFlags, componentDescription.componentManufacturer,
               componentDescription.componentType, componentDescription.componentSubType)

        self.sampler = sampler
        let auSampler = AVAudioUnitSampler()
        switch sampler.start(auSampler: auSampler) {
        case .success: self.wrapped = auSampler.auAudioUnit
        case .failure(let what):
            os_log(.error, log: log, "failed to start sampler - %{public}s", what.localizedDescription)
            throw what
        }

        self.activePatchManager = activePatchManager

        try super.init(componentDescription: componentDescription, options: [])

        os_log(.error, log:log, "init - done")
    }

    override public func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration])
        -> IndexSet {
        os_log(.error, log: log, "supportedViewConfiigurations")
        let indices = availableViewConfigurations.enumerated().compactMap { $0.1.height > 270 ? $0.0 : nil }
        os_log(.error, log: log, "indices: %{public}s", indices.debugDescription)
        return IndexSet(indices)
    }

    override public var component: AudioComponent { wrapped.component }

    override public func allocateRenderResources() throws {
        os_log(.error, log: log, "allocateRenderResources - %{public}d", outputBusses.count)
        for index in 0..<outputBusses.count {
            outputBusses[index].shouldAllocateBuffer = true
        }
        try wrapped.allocateRenderResources()
        os_log(.info, log: log, "allocateRenderResources - done")
    }

    override public func deallocateRenderResources() { wrapped.deallocateRenderResources() }

    override public var renderResourcesAllocated: Bool { wrapped.renderResourcesAllocated }

    override public func reset() { wrapped.reset() }

    override public var inputBusses: AUAudioUnitBusArray {
        os_log(.error, log: self.log, "inputBusses - %d", wrapped.inputBusses.count)
        return wrapped.inputBusses
    }

    override public var outputBusses: AUAudioUnitBusArray {
        os_log(.error, log: self.log, "outputBusses - %d", wrapped.outputBusses.count)
        return wrapped.outputBusses
    }

    override public var scheduleParameterBlock: AUScheduleParameterBlock {
        wrapped.scheduleParameterBlock
    }

    override public func token(byAddingRenderObserver observer: @escaping AURenderObserver) -> Int {
        wrapped.token(byAddingRenderObserver: observer)
    }

    override public func removeRenderObserver(_ token: Int) { wrapped.removeRenderObserver(token) }

    override public var maximumFramesToRender: AUAudioFrameCount {
        didSet { wrapped.maximumFramesToRender = self.maximumFramesToRender }
    }

    override public var parameterTree: AUParameterTree? {
        get {
            if ourParameterTree == nil { buildParameterTree() }
            os_log(.error, log: log, "parameterTree - get %d", ourParameterTree?.allParameters.count ?? 0)
            return ourParameterTree
        }
        set {
            os_log(.error, log: log, "parameterTree - set %d", newValue?.allParameters.count ?? 0)
            wrapped.parameterTree = newValue
            ourParameterTree = nil
        }
    }

    private func dumpParameters(name: String, tree: AUParameterGroup?, level: Int) {
        let indentation = String(repeating: " ", count: level)
        os_log(.error, log: self.log, "%{public}s dumpParameters BEGIN - %{public}s", indentation, name)
        defer { os_log(.error, log: self.log, "%{public}s dumpParameters END - %{public}s", indentation, name) }
        guard let children = tree?.children else { return }
        for child in children {
            os_log(.error, log: self.log, "%{public}s parameter %{public}s", indentation, child.displayName)
            if let group = child as? AUParameterGroup {
                dumpParameters(name: group.displayName, tree: group, level: level + 1)
            }
        }
    }

    private func buildParameterTree() {
        os_log(.error, log: self.log, "buildParameterTree BEGIN")
        defer { os_log(.error, log: self.log, "buildParameterTree END") }
        dumpParameters(name: "root", tree: wrapped.parameterTree, level: 0)
        guard let global = wrapped.parameterTree?.children[0] as? AUParameterGroup else { return }
        guard let clump_1 = global.children.first as? AUParameterGroup else { return }
        os_log(.error, log: self.log, "creating parameterTree from clump_1")

        var parameters: [AUParameterNode] = [
//            AUParameterTree.createParameter(withIdentifier: "Attack", name: "Attack",
//                                            address: 1000, min: 0, max: 1, unit: .mixerFaderCurve1,
//                                            unitName: "", flags: .flag_IsWritable, valueStrings: nil,
//                                            dependentParameters: nil),
//            AUParameterTree.createParameter(withIdentifier: "Decay", name: "Decay",
//                                            address: 1001, min: 0, max: 1, unit: .mixerFaderCurve1,
//                                            unitName: "", flags: .flag_IsWritable, valueStrings: nil,
//                                            dependentParameters: nil),
//            AUParameterTree.createParameter(withIdentifier: "Sustain", name: "Sustain",
//                                            address: 1002, min: 0, max: 1, unit: .mixerFaderCurve1,
//                                            unitName: "", flags: .flag_IsWritable, valueStrings: nil,
//                                            dependentParameters: nil),
//            AUParameterTree.createParameter(withIdentifier: "Release", name: "Release",
//                                            address: 1003, min: 0, max: 1, unit: .mixerFaderCurve1,
//                                            unitName: "", flags: .flag_IsWritable, valueStrings: nil,
//                                            dependentParameters: nil)
        ]

        parameters.append(contentsOf: clump_1.children)

        ourParameterTree = AUParameterTree.createTree(withChildren: parameters)
        dumpParameters(name: clump_1.displayName, tree: ourParameterTree, level: 0)
    }

    override public func parametersForOverview(withCount count: Int) -> [NSNumber] {
        os_log(.error, log: log, "parametersForOverview: %d", count)
        if ourParameterTree == nil { buildParameterTree() }
        if ourParameterTree?.children.count ?? 0 < 1 { return [] }
        return [0]
    }

    override public var allParameterValues: Bool {
        wrapped.allParameterValues
    }

    override public var isMusicDeviceOrEffect: Bool { true }

    override public var virtualMIDICableCount: Int {
        os_log(.error, log: self.log, "virtualMIDICableCount - %d", wrapped.virtualMIDICableCount)
        return wrapped.virtualMIDICableCount
    }

    override public var midiOutputNames: [String] { wrapped.midiOutputNames }

    override public var midiOutputEventBlock: AUMIDIOutputEventBlock? {
        get { wrapped.midiOutputEventBlock }
        set { wrapped.midiOutputEventBlock = newValue }
    }

    private var activeSoundFontPatchKey: String { "soundFontPatch" }

    override public var fullState: [String : Any]? {
        get {
            var fullState = wrapped.fullState ?? [:]
            if let data = ActivePatchManager.encode(self.activePatchManager.active) {
                fullState[activeSoundFontPatchKey] = data
            }
            return fullState
        }
        set {
            if let fullState = newValue {
                if let data = fullState[activeSoundFontPatchKey] as? Data {
                    if let value = ActivePatchManager.decode(data) {
                        self.activePatchManager.setActive(value)
                    }
                }
            }
            // wrapped.fullState = newValue
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

    override public func startHardware() throws { try wrapped.startHardware() }

    override public func stopHardware() { wrapped.stopHardware() }

    override public var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? {
        let block = self.wrapped.scheduleMIDIEventBlock
        let log = self.log
        return { (when: AUEventSampleTime, channel: UInt8, count: Int, bytes: UnsafePointer<UInt8>) in
            os_log(.error, log: log,
                   "scheduleMIDIEventBlock - when: %d chan: %d count: %d cmd: %d arg1: %d, arg2: %d",
                   when, channel, count, bytes[0], bytes[1], bytes[2])
            block?(when, channel, count, bytes)
        }
    }

    override public var renderBlock: AURenderBlock { wrapped.renderBlock }
    override var internalRenderBlock: AUInternalRenderBlock { wrapped.internalRenderBlock }
}
