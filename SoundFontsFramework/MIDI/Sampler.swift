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
    private let reverb: Reverb?
    private let delay: Delay?
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
    public init(mode: Mode, activePatchManager: ActivePatchManager, reverb: Reverb?, delay: Delay?) {
        self.mode = mode
        self.activePatchManager = activePatchManager
        self.reverb = reverb
        self.delay = delay
        super.init()
    }

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.

     - returns: Result value indicating success or failure
     */
    public func start() -> Result<AVAudioUnitSampler?, SamplerStartFailure> {
        os_log(.info, log: log, "start")
        auSampler = AVAudioUnitSampler()
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

    private func startEngine() -> Result<AVAudioUnitSampler?, SamplerStartFailure> {
        guard let sampler = auSampler else { return .failure(.noSampler) }
        let engine = AVAudioEngine()
        self.engine = engine

        os_log(.debug, log: log, "attaching sampler")
        engine.attach(sampler)

        if mode == .standalone {
            os_log(.debug, log: log, "connecting sampler")

            guard let reverb = self.reverb?.audioUnit else { fatalError("unexpectd nil Reverb") }
            engine.attach(reverb)
            engine.connect(reverb, to: engine.mainMixerNode, format: nil)

            guard let delay = self.delay?.audioUnit else { fatalError("unexpectd nil Delay") }
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
        }

        return loadActivePreset()
    }

    /**
     Ask the sampler to use the active preset held by the ActivePatchManager.

     - parameter afterLoadblock: callback to invoke after the load is successfully done

     - returns: Result instance indicating success or failure
     */
    public func loadActivePreset(_ afterLoadBlock: (() -> Void)? = nil) -> Result<AVAudioUnitSampler?, SamplerStartFailure> {
        os_log(.info, log: log, "loadActivePreset - %{public}s", activePatchManager.active.description)

        // Ok if the sampler is not yet available. We will apply the patch when it is
        guard let sampler = auSampler else { return .success(.none) }
        guard let soundFont = activePatchManager.soundFont else { return .success(sampler) }
        guard let patch = activePatchManager.patch else { return .success(sampler) }
        let favorite = activePatchManager.favorite

        presetChangeManager.change(sampler: sampler, url: soundFont.fileURL, program: UInt8(patch.program), bankMSB: UInt8(patch.bankMSB), bankLSB: UInt8(patch.bankLSB)) {
            if let fav = favorite {
                self.setGain(fav.gain)
                self.setPan(fav.pan)
            }

            if let delay = self.delay {
                let config = patch.delayConfig ?? delay.active.toggleEnabled()
                delay.active = config
            }

            if let reverb = self.reverb {
                let config = patch.reverbConfig ?? reverb.active.toggleEnabled()
                reverb.active = config
            }

            self.loaded = true

            DispatchQueue.main.async {
                afterLoadBlock?()
                self.notify(.loaded(patch: self.activePatchManager.active))
            }
        }

        return .success(sampler)
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
     Start playing a sound at the given pitch. If given velocity is 0, then stop playing the note.

     - parameter midiValue: MIDI value that indicates the pitch to play
     - parameter velocity: how loud to play the note (1-127)
     */
    public func noteOn(_ midiValue: UInt8, velocity: UInt8) {
        guard activePatchManager.active != .none else { return }
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
        auSampler?.stopNote(midiValue, onChannel: 0)
    }

    /**
     After-touch for the given playing note.

     - parameter midiValue: MIDI value that indicates the pitch being played
     - parameter pressure: the after-touch pressure value for the key
     */
    public func polyphonicKeyPressure(_ midiValue: UInt8, pressure: UInt8) {
        os_log(.debug, log: log, "polyphonicKeyPressure - %d %d", midiValue, pressure)
        auSampler?.sendPressure(forKey: midiValue, withValue: pressure, onChannel: 0)
    }

    /**
     After-touch for the whole channel.

     - parameter pressure: the after-touch pressure value for all of the playing keys
     */
    public func channelPressure(_ pressure: UInt8) {
        os_log(.debug, log: log, "channelPressure - %d", pressure)
        auSampler?.sendPressure(pressure, onChannel: 0)
    }

    /**
     Pitch-bend controller value.

     - parameter value: the controller value. Middle is 0x200
     */
    public func pitchBendChange(_ value: UInt16) {
        os_log(.debug, log: log, "pitchBend - %d", value)
        auSampler?.sendPitchBend(value, onChannel: 0)
    }

    public func controlChange(_ controller: UInt8, value: UInt8) {
        os_log(.debug, log: log, "controllerChange - %d %d", controller, value)
        auSampler?.sendController(controller, withValue: value, onChannel: 0)
    }

    public func programChange(_ program: UInt8) {
        os_log(.debug, log: log, "programChange - %d", program)
        auSampler?.sendProgramChange(program, onChannel: 0)
    }
}
