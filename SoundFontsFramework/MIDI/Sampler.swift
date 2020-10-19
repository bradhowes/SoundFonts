// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

public enum SamplerEvent {
    case loaded(patch: ActivePatchKind)
}

public enum SamplerStartFailure: Error {
    case noSampler
    case sessionActivating(error: NSError)
    case engineStarting(error: NSError)
    case patchLoading(error: NSError)
}

/**
 This class encapsulates Apple's AVAudioUnitSampler in order to load MIDI soundbank.
 */
public final class Sampler: SubscriptionManager<SamplerEvent> {
    private lazy var log = Logging.logger("Samp")

    /// Largest MIDI value available for the last key
    public static let maxMidiValue = 12 * 9 // C8

    public enum Mode {
        case standalone
        case audiounit
    }

    private let mode: Mode
    private let activePatchManager: ActivePatchManager
    private let presetChangeManager = PresetChangeManager()
    private var engine: AVAudioEngine?
    private var auSampler: AVAudioUnitSampler?
    private var loaded: Bool = false

    /// Expose the underlying sampler's auAudioUnit property so that it can be used in an AudioUnit extension
    private var auAudioUnit: AUAudioUnit? { auSampler?.auAudioUnit }

    /**
     Create a new instance of a Sampler.

     In `standalone` mode, the sampler will create a `AVAudioEngine` to use to host the sampler and to generate sound.
     In `audiounit` mode, the sampler will exist on its own and will expect an AUv3 host to provide the appropriate
     context to generate sound from its output.

     - parameter mode: determines how the sampler is hosted.
     */
    public init(mode: Mode, activePatchManager: ActivePatchManager) {
        self.mode = mode
        self.activePatchManager = activePatchManager
        super.init()
    }

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.

     - returns: Result value indicating success or failure
     */
    public func start(auSampler: AVAudioUnitSampler) -> Result<Void, SamplerStartFailure> {
        os_log(.info, log: log, "start")
        self.auSampler = auSampler
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
                sampler.reset()
                engine.detach(sampler)
            }
            engine.reset()
        }

        auSampler = nil
        engine = nil
    }

    private func startEngine() -> Result<Void, SamplerStartFailure> {
        guard let sampler = auSampler else { return .failure(.noSampler) }
        let engine = AVAudioEngine()
        self.engine = engine

        os_log(.debug, log: log, "attaching sampler")
        engine.attach(sampler)

        if mode == .standalone {
            os_log(.debug, log: log, "connecting sampler")
            engine.connect(sampler, to: engine.mainMixerNode, fromBus: 0, toBus: engine.mainMixerNode.nextAvailableInputBus, format: sampler.outputFormat(forBus: 0))
            do {
                os_log(.debug, log: log, "starting engine")
                try engine.start()
            } catch let error as NSError {
                return .failure(.engineStarting(error: error))
            }
        }

        return loadActivePreset()
    }

    /**
     Ask the sampler to use the active preset held by the ActivePatchManager.

     - parameter afterLoadblock: callback to invoke after the load is successfully done

     - returns: Result instance indicating success or failure
     */
    public func loadActivePreset(_ afterLoadBlock: (() -> Void)? = nil) -> Result<Void, SamplerStartFailure> {
        os_log(.info, log: log, "loadActivePreset - %{public}s", activePatchManager.active.description)

        // Ok if the sampler is not yet available. We will apply the patch when it is
        guard let sampler = auSampler else { return .success(()) }
        guard let soundFont = activePatchManager.soundFont else { return .success(()) }
        guard let patch = activePatchManager.patch else { return .success(()) }
        let favorite = activePatchManager.favorite

        presetChangeManager.change(sampler: sampler, url: soundFont.fileURL, program: UInt8(patch.program), bankMSB: UInt8(patch.bankMSB), bankLSB: UInt8(patch.bankLSB)) {
            if let fav = favorite {
                self.setGain(fav.gain)
                self.setPan(fav.pan)
            }
            self.loaded = true
            afterLoadBlock?()
            DispatchQueue.main.async {
                self.notify(.loaded(patch: self.activePatchManager.active))
            }
        }

        return .success(())
    }

    /**
     Set the AVAudioUnitSampler masterGain value

     - parameter value: the value to set
     */
    public func setGain(_ value: Float) {
        auSampler?.masterGain = value
    }

    /**
     Set the AVAudioUnitSampler stereoPan value

     - parameter value: the value to set
     */
    public func setPan(_ value: Float) {
        auSampler?.stereoPan = value
    }

    /**
     Start playing a sound at the given pitch.

     - parameter midiValue: MIDI value that indicates the pitch to play
     */
    public func noteOn(_ midiValue: Int, velocity: Int = 64) {
        os_log(.info, log: log, "noteOn - %d", midiValue)
        guard activePatchManager.active != .none else { return }
        auSampler?.startNote(UInt8(midiValue), withVelocity: UInt8(velocity), onChannel: UInt8(0))
    }

    /**
     Stop playing a sound at the given pitch.

     - parameter midiValue: MIDI value that indicates the pitch to stop
     */
    public func noteOff(_ midiValue: Int) {
        os_log(.info, log: log, "noteOff - %d", midiValue)
        auSampler?.stopNote(UInt8(midiValue), onChannel: UInt8(0))
    }

    public func sendMIDI(_ cmd: UInt8, data1: UInt8, data2: UInt8) {
        os_log(.info, log: log, "sendMIDI - %d %d %d", cmd, data1, data2)
        auSampler?.sendMIDIEvent(cmd, data1: data1, data2: data2)
    }
}
