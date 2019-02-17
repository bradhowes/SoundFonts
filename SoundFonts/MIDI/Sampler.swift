//
//  Sampler.swift
//  Miles
//
//  Created by Brad Howes on 11/03/2018.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

/**
 This class encapsulates Apple's AVAudioUnitSampler in order to load MIDI soundbank.
 */
public class Sampler {
    
    /// The volume of the Sampler when connected to the AVAUdioEngine
    public var volume: Float {
        set {
            self.ausampler.volume = newValue
        }
        get {
            return self.ausampler.volume
        }
    }

    private let engine: AVAudioEngine = AVAudioEngine()
    
    /// The actual AVAudioSampler being used to generate audio from MIDI traffic
    private let ausampler: AVAudioUnitSampler = AVAudioUnitSampler()

    /**
     Creates a new Sampler instance for the specified instrument voice.
 
     - parameter engine: the AVAudioEngine instance to use
     - parameter voice: the desired voice type to use
     */
    public init(patch: Patch) {
        engine.attach(ausampler)
        engine.connect(ausampler, to: engine.mainMixerNode, fromBus: 0,
                       toBus: engine.mainMixerNode.nextAvailableInputBus,
                       format: ausampler.outputFormat(forBus: 0))
        try? engine.start()
        ausampler.masterGain = 1.0
        load(patch: patch)
    }

    /**
     Set the InstrumentVoice (sound font) and patch to use in eh AVAudioUnitSampler when generating audio output.
    
     - parameter voice: the sound font and patch to use
     */
    public func load(patch: Patch) {
        do {
            try ausampler.loadSoundBankInstrument(at: patch.soundFont.fileURL, program: UInt8(patch.patch),
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
        ausampler.masterGain = value
    }

    /**
     Set the AVAudioUnitSampler stereoPan value
     
     - parameter value: the value to set
     */
    public func setPan(_ value: Float) {
        ausampler.stereoPan = value
    }
    
    /**
     Start playing a sound at the given pitch
    
     - parameter midiValue: MIDI value that indicates the pitch to play
     */
    public func noteOn(_ midiValue: Int) {
        ausampler.startNote(UInt8(midiValue), withVelocity: UInt8(64), onChannel: UInt8(0))
    }

    /**
     Stop playing a sound at the given pitch
    
     - parameter midiValue: MIDI value that indicates the pitch to stop
     */
    public func noteOff(_ midiValue: Int) {
        ausampler.stopNote(UInt8(midiValue), onChannel: UInt8(0))
    }
}
