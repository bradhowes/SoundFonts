// Copyright © 2020 Brad Howes. All rights reserved.

import os
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
    private var wrapped: AUAudioUnit { sampler.auAudioUnit! }

    public init(componentDescription: AudioComponentDescription, sampler: Sampler,
                activePatchManager: ActivePatchManager) throws {
        os_log(.info, log:log, "init - flags: %d man: %d type: sub: %d",
               componentDescription.componentFlags, componentDescription.componentManufacturer,
               componentDescription.componentType, componentDescription.componentSubType)

        self.sampler = sampler
        self.activePatchManager = activePatchManager

        if case let .failure(failure) = sampler.start() {
            os_log(.error, log: log, "failed to start sampler - %{public}s", failure.localizedDescription)
        }

        try super.init(componentDescription: componentDescription, options: [])

        os_log(.info, log:log, "init - done")
    }

    override public var component: AudioComponent { wrapped.component }

    override public func allocateRenderResources() throws {
        os_log(.info, log: log, "allocateRenderResources - %{public}d", outputBusses.count)
        for index in 0..<outputBusses.count {
            outputBusses[index].shouldAllocateBuffer = true
        }
        try wrapped.allocateRenderResources()
        os_log(.info, log: log, "allocateRenderResources - done")
    }

    override public func deallocateRenderResources() { wrapped.deallocateRenderResources() }
    override public var renderResourcesAllocated: Bool { wrapped.renderResourcesAllocated }
    override public func reset() { wrapped.reset() }
    override public var inputBusses: AUAudioUnitBusArray { wrapped.inputBusses }
    override public var outputBusses: AUAudioUnitBusArray { wrapped.outputBusses }
    override public var renderBlock: AURenderBlock { wrapped.renderBlock }
    override public var scheduleParameterBlock: AUScheduleParameterBlock { wrapped.scheduleParameterBlock }

    override public func token(byAddingRenderObserver observer: @escaping AURenderObserver) -> Int {
        wrapped.token(byAddingRenderObserver: observer)
    }

    override public func removeRenderObserver(_ token: Int) { wrapped.removeRenderObserver(token) }

    override public var maximumFramesToRender: AUAudioFrameCount {
        didSet { wrapped.maximumFramesToRender = self.maximumFramesToRender }
    }

    override public var parameterTree: AUParameterTree? {
        get { wrapped.parameterTree }
        set { wrapped.parameterTree = newValue }
    }

    override public func parametersForOverview(withCount count: Int) -> [NSNumber] {
        wrapped.parametersForOverview(withCount: count)
    }

    override public var allParameterValues: Bool { wrapped.allParameterValues }
    override public var isMusicDeviceOrEffect: Bool { true }
    override public var virtualMIDICableCount: Int { wrapped.virtualMIDICableCount }
    override public var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? { wrapped.scheduleMIDIEventBlock }

    override public var midiOutputNames: [String] { wrapped.midiOutputNames }
    override public var midiOutputEventBlock: AUMIDIOutputEventBlock? {
        get { wrapped.midiOutputEventBlock }
        set { wrapped.midiOutputEventBlock = newValue }
    }

    override public var fullState: [String : Any]? {
        get {
            var fullState = wrapped.fullState ?? [:]
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.sampler.activePatchKind) {
                fullState["soundFontPatch"] = data
            }
            return fullState
        }
        set {
            wrapped.fullState = newValue
            if let fullState = newValue {
                if let data = fullState["soundFontPatch"] as? Data {
                    let decoder = JSONDecoder()
                    if let activePatchKind = try? decoder.decode(ActivePatchKind.self, from: data) {
                        self.activePatchManager.setActive(activePatchKind)
                    }
                }
            }
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
    override var internalRenderBlock: AUInternalRenderBlock { wrapped.internalRenderBlock }
}
