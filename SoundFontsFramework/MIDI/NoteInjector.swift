// Copyright © 2020 Brad Howes. All rights reserved.

import os
import CoreAudioKit

/**
 Submit a sequence of MIDI events to play a A4 note. Used when switching preset/patches.
 */
public struct NoteInjector {
    private let log = Logging.logger("NoteInjector")
    private let note: UInt8 = 69 // A4
    private let noteOnDuration = 1.0
    private let playingQueue = DispatchQueue(label: "NoteInjector.playingQueue", qos: .userInteractive, attributes: [],
                                             autoreleaseFrequency: .never,
                                             target: DispatchQueue.global(qos: .userInteractive))
    private var workItems = [DispatchWorkItem]()

    public init() {}

    /**
     Post MIDI commands to Sampler to play a short note.

     - parameter sampler: the sampler to command
     */
    public mutating func post(to sampler: Sampler) {
        guard Settings.shared.playSample == true else { return }
        let note = self.note
        let noteOn = DispatchWorkItem { sampler.noteOn(note, velocity: 32) }
        playingQueue.asyncAfter(deadline: .now() + 0.1, execute: noteOn)

        let noteOff = DispatchWorkItem { sampler.noteOff(note) }
        playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)

        workItems.forEach { $0.cancel() }
        workItems = [noteOn, noteOff]
    }

    /**
     Post MIDI commands to an audio unit to play a short note.

     - parameter audioUnit: the audio unit to command
     */
    public mutating func post(to audioUnit: AUAudioUnit) {
        guard Settings.shared.playSample == true else { return }

        guard let noteBlock = audioUnit.scheduleMIDIEventBlock else { return }
        os_log(.info, log: log, "post - valid noteBlock")

        let channel: UInt8 = 0
        let channel1NoteOn: UInt8 = 0x90

        let note = UInt8(self.note)
        let velocity: UInt8 = 64

        let noteOn = DispatchWorkItem {
            let bytes: [UInt8] = [channel1NoteOn, note, velocity]
            noteBlock(AUEventSampleTimeImmediate, channel, bytes.count, bytes)
        }
        playingQueue.async(execute: noteOn)

        let noteOff = DispatchWorkItem {
            let bytes: [UInt8] = [channel1NoteOn, note, 0]
            noteBlock(AUEventSampleTimeImmediate, 0, bytes.count, bytes)
        }
        playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)

        workItems.forEach { $0.cancel() }
        workItems = [noteOn, noteOff]
    }
}
