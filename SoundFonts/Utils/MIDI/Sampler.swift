// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox

/**
 This class encapsulates Apple's AVAudioUnitSampler in order to load MIDI soundbank.
 */
public class Sampler {
    private var engine: AVAudioEngine?
    private var ausampler: AVAudioUnitSampler?
    private var patch: Patch?

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.
     */
    public func start() {
        let engine = AVAudioEngine()
        self.engine = engine
        let sampler = AVAudioUnitSampler()
        self.ausampler = sampler

        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, fromBus: 0, toBus: engine.mainMixerNode.nextAvailableInputBus,
                       format: sampler.outputFormat(forBus: 0))
        if let patch = self.patch {
            load(patch: patch)
        }

        try? engine.start()
    }

    /**
     Stop the existing audio engine. Releases the sampler and engine.
     */
    public func stop() {
        engine?.stop()
        ausampler = nil
        engine = nil
    }

    /**
     Set the sound font and patch to use in the AVAudioUnitSampler to generate audio output.
    
     - parameter patch: the sound font and patch to use
     */
    public func load(patch: Patch) {
        self.patch = patch
        guard let sampler = self.ausampler else { return }
        guard let soundFont = patch.soundFont else { return }
        do {
            try sampler.loadSoundBankInstrument(at: soundFont.fileURL, program: UInt8(patch.patch),
                                                bankMSB: UInt8(patch.bankMSB), bankLSB: UInt8(patch.bankLSB))
        } catch let error as NSError {
            print("\(error.localizedDescription)")
            fatalError("Could not load file")
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
