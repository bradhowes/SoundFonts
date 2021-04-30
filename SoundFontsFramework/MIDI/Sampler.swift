// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

public enum SamplerEvent {
    case running
    case loaded(patch: ActivePatchKind)
}

public enum SamplerStartFailure: Error {
    case noSampler
    case sessionActivating(error: NSError)
    case engineStarting(error: NSError)
    case patchLoading(error: NSError)
}

/**
 This class encapsulates Apple's AVAudioUnitSampler in order to load MIDI sound bank.
 */
public final class Sampler: SubscriptionManager<SamplerEvent> {
    private lazy var log = Logging.logger("Samp")

    /// Largest MIDI value available for the last key
    public static let maxMidiValue = 12 * 9 // C8

    public static let setTuningNotification = TypedNotification<Float>(name: .setTuning)
    public static let setPitchBendRangeNotification = TypedNotification<Int>(name: .setPitchBendRange)

    public typealias StartResult = Result<AVAudioUnitSampler?, SamplerStartFailure>

    public enum Mode {
        case standalone
        case audioUnit
    }

    private let mode: Mode
    private let activePatchManager: ActivePatchManager
    private let reverbEffect: ReverbEffect?
    private let delayEffect: DelayEffect?
    private let presetChangeManager = PresetChangeManager()
    private var engine: AVAudioEngine?
    public private(set) var auSampler: AVAudioUnitSampler?
    private var loaded: Bool = false

    /// Expose the underlying sampler's auAudioUnit property so that it can be used in an AudioUnit extension
    private var auAudioUnit: AUAudioUnit? { auSampler?.auAudioUnit }
    private var presetConfigNotifier: NotificationObserver?
    private var setGlobalTuningNotifier: NotificationObserver?
    private var setGlobalPitchBendRangeNotifier: NotificationObserver?

    /**
     Create a new instance of a Sampler.

     In `standalone` mode, the sampler will create a `AVAudioEngine` to use to host the sampler and to generate sound.
     In `audioUnit` mode, the sampler will exist on its own and will expect an AUv3 host to provide the appropriate
     context to generate sound from its output.

     - parameter mode: determines how the sampler is hosted.
     */
    public init(mode: Mode, activePatchManager: ActivePatchManager, reverb: ReverbEffect?, delay: DelayEffect?) {
        self.mode = mode
        self.activePatchManager = activePatchManager
        self.reverbEffect = reverb
        self.delayEffect = delay
        super.init()

        presetConfigNotifier = PresetConfig.changedNotification.registerOnAny { [weak self] presetConfig in
            guard let self = self else { return }
            self.applyPresetConfig(presetConfig)
        }

        setGlobalTuningNotifier = Self.setTuningNotification.registerOnAny { [weak self] tuning in
            self?.setTuning(tuning)
        }

        setGlobalPitchBendRangeNotifier = Self.setPitchBendRangeNotification.registerOnAny { [weak self] range in
            self?.setPitchBendRange(range)
        }
    }

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.

     - returns: Result value indicating success or failure
     */
    public func start() -> StartResult {
        os_log(.info, log: log, "start")
        auSampler = AVAudioUnitSampler()
        if Settings.shared.globalTuningEnabled {
            auSampler?.globalTuning = Settings.shared.globalTuning
        }
        presetChangeManager.start()
        return startEngine()
    }

    /**
     Stop the existing audio engine. Releases the sampler and engine.
     */
    public func stop() {
        os_log(.info, log: log, "stop")
        presetChangeManager.stop()

        if let engine = self.engine {
            engine.stop()
            if let sampler = self.auSampler {
                engine.detach(sampler)
            }
            engine.reset()
        }

        if let sampler = self.auSampler {
            sampler.reset()
        }

        auSampler = nil
        engine = nil
    }

    /**
     Ask the sampler to use the active preset held by the ActivePatchManager.

     - parameter afterLoadBlock: callback to invoke after the load is successfully done

     - returns: Result instance indicating success or failure
     */
    public func loadActivePreset(_ afterLoadBlock: (() -> Void)? = nil) -> StartResult {
        os_log(.info, log: log, "loadActivePreset - %{public}s", activePatchManager.active.description)

        // Ok if the sampler is not yet available. We will apply the patch when it is
        guard let sampler = auSampler else {
            os_log(.info, log: log, "no sampler yet")
            return .success(.none)
        }

        guard let soundFont = activePatchManager.soundFont else {
            os_log(.info, log: log, "activePatchManager.soundFont is nil")
            return .success(sampler)
        }

        guard let patch = activePatchManager.patch else {
            os_log(.info, log: log, "activePatchManager.patch is nil")
            return .success(sampler)
        }

        let favorite = activePatchManager.favorite
        self.loaded = false
        let presetConfig = favorite?.presetConfig ?? patch.presetConfig

        os_log(.info, log: log, "requesting preset change")
        presetChangeManager.change(sampler: sampler, url: soundFont.fileURL, program: UInt8(patch.program),
                                   bankMSB: UInt8(patch.bankMSB), bankLSB: UInt8(patch.bankLSB)) { [weak self] in
            guard let self = self else { return }
            os_log(.info, log: self.log, "request complete")
            self.applyPresetConfig(presetConfig)
            DispatchQueue.main.async {
                self.loaded = true
                afterLoadBlock?()
                os_log(.info, log: self.log, "notifing loaded")
                self.notify(.loaded(patch: self.activePatchManager.active))
            }
        }

        os_log(.info, log: log, "done")
        return .success(sampler)
    }
}

extension Sampler {

    /**
     Set the AVAudioUnitSampler tuning value

     - parameter value: the value to set in cents (+/- 2400)
     */
    public func setTuning(_ value: Float) {
        os_log(.info, log: log, "setTuning: %f", value)
        auSampler?.globalTuning = value
    }

    /**
     Set the AVAudioUnitSampler masterGain value

     - parameter value: the value to set
     */
    public func setGain(_ value: Float) {
        os_log(.info, log: log, "setGain: %f", value)
        auSampler?.masterGain = value
    }

    /**
     Set the AVAudioUnitSampler stereoPan value

     - parameter value: the value to set
     */
    public func setPan(_ value: Float) {
        os_log(.info, log: log, "setPan: %f", value)
        auSampler?.stereoPan = value
    }
}

extension Sampler {

    /**
     Start playing a sound at the given pitch. If given velocity is 0, then stop playing the note.

     - parameter midiValue: MIDI value that indicates the pitch to play
     - parameter velocity: how loud to play the note (1-127)
     */
    public func noteOn(_ midiValue: UInt8, velocity: UInt8) {
        guard activePatchManager.active != .none, self.loaded else { return }
        guard velocity > 0 else {
            noteOff(midiValue)
            return
        }
        os_log(.debug, log: log, "noteOn - %d %d", midiValue, velocity)
        auSampler?.startNote(midiValue, withVelocity: velocity, onChannel: 0)
    }

    /**
     Stop playing a sound at the given pitch.

     - parameter midiValue: MIDI value that indicates the pitch to stop
     */
    public func noteOff(_ midiValue: UInt8) {
        os_log(.debug, log: log, "noteOff - %d", midiValue)
        guard activePatchManager.active != .none, self.loaded else { return }
        auSampler?.stopNote(midiValue, onChannel: 0)
    }

    /**
     After-touch for the given playing note.

     - parameter midiValue: MIDI value that indicates the pitch being played
     - parameter pressure: the after-touch pressure value for the key
     */
    public func polyphonicKeyPressure(_ midiValue: UInt8, pressure: UInt8) {
        os_log(.debug, log: log, "polyphonicKeyPressure - %d %d", midiValue, pressure)
        guard activePatchManager.active != .none, self.loaded else { return }
        auSampler?.sendPressure(forKey: midiValue, withValue: pressure, onChannel: 0)
    }

    /**
     After-touch for the whole channel.

     - parameter pressure: the after-touch pressure value for all of the playing keys
     */
    public func channelPressure(_ pressure: UInt8) {
        os_log(.debug, log: log, "channelPressure - %d", pressure)
        guard activePatchManager.active != .none, self.loaded else { return }
        auSampler?.sendPressure(pressure, onChannel: 0)
    }

    /**
     Pitch-bend controller value.

     - parameter value: the controller value. Middle is 0x200
     */
    public func pitchBendChange(_ value: UInt16) {
        os_log(.debug, log: log, "pitchBend - %d", value)
        guard activePatchManager.active != .none, self.loaded else { return }
        auSampler?.sendPitchBend(value, onChannel: 0)
    }

    public func controlChange(_ controller: UInt8, value: UInt8) {
        os_log(.debug, log: log, "controllerChange - %d %d", controller, value)
        guard activePatchManager.active != .none, self.loaded else { return }
        auSampler?.sendController(controller, withValue: value, onChannel: 0)
    }

    public func programChange(_ program: UInt8) {
        os_log(.debug, log: log, "programChange - %d", program)
        guard activePatchManager.active != .none, self.loaded else { return }
        auSampler?.sendProgramChange(program, onChannel: 0)
    }

    /// For the future -- AVAudioUnitSampler does not support this
    public func setPitchBendRange(_ value: Int) {
        guard value > 0 && value < 25 else {
            os_log(.error, log: log, "invalid pitch bend range: %d", value)
            return
        }
        auSampler?.sendMIDIEvent(0xB0, data1: 101, data2: 0)
        auSampler?.sendMIDIEvent(0xB0, data1: 100, data2: 0)
        auSampler?.sendMIDIEvent(0xB0, data1: 0x06, data2: UInt8(value))
        auSampler?.sendMIDIEvent(0xB0, data1: 0x26, data2: 0)
    }
}

extension Sampler {

    private func startEngine() -> StartResult {
        guard let sampler = auSampler else { return .failure(.noSampler) }
        guard mode == .standalone else { return loadActivePreset() }

        os_log(.debug, log: log, "connecting sampler")
        let engine = AVAudioEngine()
        self.engine = engine

        os_log(.debug, log: log, "attaching sampler")
        engine.attach(sampler)

        guard let reverb = reverbEffect?.audioUnit else { fatalError("unexpected nil Reverb") }
        engine.attach(reverb)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)

        guard let delay = delayEffect?.audioUnit else { fatalError("unexpected nil Delay") }
        engine.attach(delay)
        engine.connect(delay, to: reverb, format: nil)
        engine.connect(sampler, to: delay, format: nil)

        engine.prepare()

        do {
            os_log(.debug, log: log, "starting engine")
            try engine.start()
        } catch let error as NSError {
            return .failure(.engineStarting(error: error))
        }

        return loadActivePreset()
    }

    private func applyPresetConfig(_ presetConfig: PresetConfig) {
        if presetConfig.presetTuningEnabled {
            setTuning(presetConfig.presetTuning)
        }
        else if Settings.shared.globalTuningEnabled {
            setTuning(Settings.shared.globalTuning)
        }
        else {
            setTuning(0.0)
        }

        if let pitchBendRange = presetConfig.pitchBendRange {
            setPitchBendRange(pitchBendRange)
        }
        else {
            setPitchBendRange(Settings.shared.pitchBendRange)
        }

        setGain(presetConfig.gain)
        setPan(presetConfig.pan)

        // - If global mode enabled, don't change anything
        // - If preset has a config use it.
        // - Otherwise, if effect was enabled disable it
        if let delay = delayEffect, !Settings.instance.delayGlobal {
            if let config = presetConfig.delayConfig {
                os_log(.debug, log: log, "reverb preset config")
                delay.active = config
            }
            else if delay.active.enabled {
                os_log(.debug, log: log, "reverb disabled")
                delay.active = delay.active.setEnabled(false)
            }
        }

        if let reverb = reverbEffect, !Settings.instance.reverbGlobal {
            if let config = presetConfig.reverbConfig {
                os_log(.debug, log: log, "delay preset config")
                reverb.active = config
            }
            else if reverb.active.enabled {
                os_log(.debug, log: log, "delay disabled")
                reverb.active = reverb.active.setEnabled(false)
            }
        }
    }
}
