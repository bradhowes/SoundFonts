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
        case noSampler
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
    private var loaded: Bool = false

    public var hasPatch: Bool { activePatchKind != .none }
    public private(set) var activePatchKind: ActivePatchKind = .none

    /// Expose the underlying sampler's auAudioUnit property so that it can be used in an AudioUnit extension
    public var auAudioUnit: AUAudioUnit? { ausampler?.auAudioUnit }

    /**
     Create a new instance of a Sampler.

     In `standalone` mode, the sampler will create a `AVAudioEngine` to use to host the sampler and to generate sound.
     In `audiounit` mode, the sampler will exist on its own and will expect an AUv3 host to provide the appropriate
     context to generate sound from its output.

     - parameter mode: determines how the sampler is hosted.
     */
    public init(mode: Mode) {
        self.mode = mode
    }

    /**
     Connect up a sampler and start the audio engine to allow the sampler to make sounds.

     - returns: Result value indicating success or failure
     */
    public func start() -> Result<Void, Failure> {
        os_log(.info, log: log, "start")
        ausampler = AVAudioUnitSampler()
        return startEngine()
    }

    private func loadActivePatch() -> Result<Void, Failure> {
        loaded ? .success(()) : load(activePatchKind: activePatchKind, playSample: false)
    }

    /**
     Stop the existing audio engine. Releases the sampler and engine.
     */
    public func stop() {
        os_log(.info, log: log, "stop")
        engine?.stop()
    }

    private func startEngine() -> Result<Void, Failure> {
        guard let sampler = ausampler else { return .failure(.noSampler) }
        let engine = AVAudioEngine()
        self.engine = engine

        os_log(.debug, log: log, "attaching sampler")
        engine.attach(sampler)

        if mode == .standalone {
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
             
        return loadActivePatch()
    }

    /**
     Set the sound font and patch to use in the AVAudioUnitSampler to generate audio output.
    
     - parameter activePatchKind: the sound font and patch to use

     - returns: Result instance indicating success or failure
     */
    public func load(activePatchKind: ActivePatchKind, playSample: Bool) -> Result<Void, Failure> {
        os_log(.info, log: log, "load - %s", activePatchKind.description)

        self.activePatchKind = activePatchKind

        // Ok if the sampler is not yet available. We will apply the patch when it is
        guard let sampler = self.ausampler, let soundFontPatch = activePatchKind.soundFontPatch else {
            return .success(())
        }

        if let favorite = activePatchKind.favorite {
            setGain(favorite.gain)
            setPan(favorite.pan)
        }

        do {
            os_log(.info, log: log, "begin loading")
            try sampler.loadSoundBankInstrument(at: soundFontPatch.soundFont.fileURL,
                                                program: UInt8(soundFontPatch.patch.patch),
                                                bankMSB: UInt8(soundFontPatch.patch.bankMSB),
                                                bankLSB: UInt8(soundFontPatch.patch.bankLSB))
            os_log(.info, log: log, "end loading")
            loaded = true
            if playSample {
                self.playSample()
            }
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
        os_log(.info, log: log, "noteOn - %d", midiValue)
        guard let sampler = self.ausampler, activePatchKind != .none else { return }
        sampler.startNote(UInt8(midiValue), withVelocity: UInt8(64), onChannel: UInt8(0))
    }

    /**
     Stop playing a sound at the given pitch.
    
     - parameter midiValue: MIDI value that indicates the pitch to stop
     */
    public func noteOff(_ midiValue: Int) {
        os_log(.info, log: log, "noteOff - %d", midiValue)
        guard let sampler = self.ausampler else { return }
        sampler.stopNote(UInt8(midiValue), onChannel: UInt8(0))
    }

    var workItem: DispatchWorkItem?

    private func playSample() {
        let note = Note("A4")!.midiNoteValue
        self.workItem?.cancel()
        self.workItem = DispatchWorkItem { [weak self] in
            guard let wself = self else { return }
            wself.noteOff(note)
            wself.noteOn(note)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let wself = self else { return }
                wself.noteOff(note)
            }
        }

        DispatchQueue.main.async(execute: self.workItem!)
    }
}
