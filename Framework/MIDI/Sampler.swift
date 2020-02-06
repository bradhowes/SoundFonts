// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

/**
 This class encapsulates Apple's AVAudioUnitSampler in order to load MIDI soundbank.
 */
public final class Sampler {
    private lazy var log = Logging.logger("Samp")

    /// Largest MIDI value available for the last key
    public static let maxMidiValue = 12 * 9 // C9

    public enum Failure: Error {
        case engineStarting(error: NSError)
        case patchLoading(error: NSError)
    }

    public enum Mode {
        case standalone
        case audiounit
    }

    private let mode: Mode
    private var engine: AVAudioEngine?
    private var ausampler: AVAudioUnitSampler?
    private var activePatchKind: ActivePatchKind?

    /// Expose the underlying sampler's auAudioUnit property so that it can be used in an AudioUnit extension
    public var auAudioUnit: AUAudioUnit { return ausampler!.auAudioUnit }

    /**
     Create a new instance of a Sampler.

     - parameter mode: <#Describe mode#>
     */
    public init(mode: Mode) {
        self.mode = mode
    }

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.
     */
    public func start() -> Result<Void, Failure> {
        os_log(.info, log: log, "start")

        let sampler = AVAudioUnitSampler()
        self.ausampler = sampler

        if case .standalone = mode {
            let engine = AVAudioEngine()
            self.engine = engine

            os_log(.debug, log: log, "attaching sampler")
            engine.attach(sampler)

            os_log(.debug, log: log, "connecting sampler")
            engine.connect(sampler, to: engine.mainMixerNode,
                           fromBus: 0, toBus: engine.mainMixerNode.nextAvailableInputBus,
                           format: sampler.outputFormat(forBus: 0))

            do {
                os_log(.debug, log: log, "starting engine")
                try engine.start()
            } catch let error as NSError {
                return .failure(.engineStarting(error: error))
            }
        }

        if let activePatchKind = self.activePatchKind {
            self.activePatchKind = nil

            os_log(.info, log: log, "done")
            return load(activePatchKind: activePatchKind)
        }

        os_log(.info, log: log, "done")
        return .success(())
    }

    /**
     Stop the existing audio engine. Releases the sampler and engine.
     */
    public func stop() {
        os_log(.info, log: log, "stop")
        engine?.stop()
    }

    /**
     Set the sound font and patch to use in the AVAudioUnitSampler to generate audio output.
    
     - parameter patch: the sound font and patch to use
     */
    public func load(activePatchKind: ActivePatchKind) -> Result<Void, Failure> {
        os_log(.info, log: log, "load - %s", activePatchKind.description)

        guard self.activePatchKind?.soundFontPatch != activePatchKind.soundFontPatch else {
            os_log(.info, log: log, "already loaded")
            return .success(())
        }

        self.activePatchKind = activePatchKind

        // Ok if the sampler is not yet available. We will apply the patch when it is
        guard let sampler = self.ausampler else { return .success(()) }

        if let favorite = activePatchKind.favorite {
            setGain(favorite.gain)
            setPan(favorite.pan)
        }

        let soundFontPatch = activePatchKind.soundFontPatch
        do {
            os_log(.info, log: log, "begin loading")
            try sampler.loadSoundBankInstrument(at: soundFontPatch.soundFont.fileURL,
                                                program: UInt8(soundFontPatch.patch.patch),
                                                bankMSB: UInt8(soundFontPatch.patch.bankMSB),
                                                bankLSB: UInt8(soundFontPatch.patch.bankLSB))
            os_log(.info, log: log, "end loading")
            return .success(())
        } catch let error as NSError {
            os_log(.error, log: log, "failed loading - %s", error.localizedDescription)
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
