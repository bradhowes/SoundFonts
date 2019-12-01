// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

/**
 This class encapsulates Apple's AVAudioUnitSampler in order to load MIDI soundbank.
 */
public class Sampler {
    private lazy var logger = Logging.logger("Samp")

    private var engine: AVAudioEngine?
    private var ausampler: AVAudioUnitSampler?
    private var patch: Patch?

    public enum Failure: Error {
        case engineStarting(error: NSError)
        case patchLoading(error: NSError)
    }

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.
     */
    public func start() -> Result<Void, Failure> {
        os_log(.info, log: logger, "start")

        let engine = AVAudioEngine()
        self.engine = engine
        let sampler = AVAudioUnitSampler()
        self.ausampler = sampler

        os_log(.debug, log: logger, "attaching sampler")
        engine.attach(sampler)
        os_log(.debug, log: logger, "connecting sampler")
        engine.connect(sampler, to: engine.mainMixerNode, fromBus: 0, toBus: engine.mainMixerNode.nextAvailableInputBus,
                       format: sampler.outputFormat(forBus: 0))

        do {
            os_log(.debug, log: logger, "starting engine")
            try engine.start()
        } catch let error as NSError {
            return .failure(.engineStarting(error: error))
        }

        if let patch = self.patch {
            return load(patch: patch)
        }

        os_log(.info, log: logger, "done")
        return .success(())
    }

    /**
     Stop the existing audio engine. Releases the sampler and engine.
     */
    public func stop() {
        os_log(.info, log: logger, "stop")
        engine?.stop()
    }

    /**
     Set the sound font and patch to use in the AVAudioUnitSampler to generate audio output.
    
     - parameter patch: the sound font and patch to use
     */
    public func load(patch: Patch) -> Result<Void, Failure> {
        os_log(.info, log: logger, "load - %s", patch.description)
        self.patch = patch

        // Ok if the sampler is not yet available. We will apply the patch when it is
        guard let sampler = self.ausampler else { return .success(()) }
        do {
            os_log(.info, log: logger, "begin loading")
            try sampler.loadSoundBankInstrument(at: patch.soundFont.fileURL, program: UInt8(patch.patch),
                                                bankMSB: UInt8(patch.bankMSB), bankLSB: UInt8(patch.bankLSB))
            os_log(.info, log: logger, "end loading")
            return .success(())
        } catch let error as NSError {
            os_log(.error, log: logger, "failed loading - %s", error.localizedDescription)
            return .failure(.patchLoading(error: error))
        }
    }

    /**
     Set the AVAudioUnitSampler masterGain value

     - parameter value: the value to set
     */
    public func setGain(_ value: Float) {
        guard let sampler = self.ausampler else { fatalError("unexpected nil ausampler") }
        sampler.masterGain = value
    }

    /**
     Set the AVAudioUnitSampler stereoPan value

     - parameter value: the value to set
     */
    public func setPan(_ value: Float) {
        guard let sampler = self.ausampler else { fatalError("unexpected nil ausampler") }
        sampler.stereoPan = value
    }

    /**
     Start playing a sound at the given pitch.
    
     - parameter midiValue: MIDI value that indicates the pitch to play
     */
    public func noteOn(_ midiValue: Int) {
        guard let sampler = self.ausampler else { return }
        sampler.startNote(UInt8(midiValue), withVelocity: UInt8(64), onChannel: UInt8(0))
    }

    /**
     Stop playing a sound at the given pitch.
    
     - parameter midiValue: MIDI value that indicates the pitch to stop
     */
    public func noteOff(_ midiValue: Int) {
        guard let sampler = self.ausampler else { return }
        sampler.stopNote(UInt8(midiValue), onChannel: UInt8(0))
    }
}
