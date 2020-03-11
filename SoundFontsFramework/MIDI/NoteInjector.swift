// Copyright © 2020 Brad Howes. All rights reserved.

import os
import CoreAudioKit

public final class NoteInjector {
    private let log = Logging.logger("NoInj")
    private let playingQueue = DispatchQueue(label: "NoteInjector.playingQueue", qos: .userInitiated)
    private var workItem: DispatchWorkItem?

    private let note = 69 // A4
    private let noteOnDuration = 0.7

    public init() {}
    
    public func post(to sampler: Sampler) {
        guard Settings[.playSample] == true else { return }
        let note = self.note
        let noteOnDuration = self.noteOnDuration

        let sequence = DispatchWorkItem { sampler.noteOff(note) }
        let noteOn = DispatchWorkItem { sampler.noteOn(note) }
        let noteOff = DispatchWorkItem { sampler.noteOff(note) }

        // Link commands together with appropriate delays.
        sequence.notify(queue: playingQueue) {
            guard !sequence.isCancelled else { return }
            self.playingQueue.asyncAfter(deadline: .now() + 0.1, execute: noteOn)
        }

        noteOn.notify(queue: playingQueue) {
            guard !sequence.isCancelled else { return }
            self.playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)
        }

        self.workItem?.cancel()
        self.workItem = sequence
        playingQueue.asyncAfter(deadline: .now() + 0.1, execute: sequence)
    }

    public func post(to audioUnit: AUAudioUnit) {
        guard Settings[.playSample] == true else { return }

        os_log(.error, log: log, "post(AudioUnit)")
        guard let noteBlock = audioUnit.scheduleMIDIEventBlock else { return }
        os_log(.error, log: log, "post - valid noteBlock")

        let logCancel = { os_log(.error, log: self.log, "cancelled") }

        // Create MIDI command sequence -- first, stop all notes
        let channel: UInt8 = 1
        let channel1ControlMode: UInt8 = 0xB0
        let allNotesOff: UInt8 = 0x7B
        let channel1NoteOff: UInt8 = 0x80
        let channel1NoteOn: UInt8 = 0x90
        let note: UInt8 = 69 // A4
        let velocity: UInt8 = 64
        let sequence = DispatchWorkItem(qos: .userInitiated, flags: []) {
            os_log(.error, log: self.log, "sending all notes off")
            let cbytes: [UInt8] = [channel1ControlMode, allNotesOff, 0]
            noteBlock(AUEventSampleTimeImmediate, channel, cbytes.count, cbytes)
        }

        // Next, play A4
        let noteOnDuration = 1.0
        let noteOn = DispatchWorkItem(qos: .userInitiated, flags: []) {
            guard !sequence.isCancelled else { logCancel(); return }
            os_log(.error, log: self.log, "sending A4 ON")
            let cbytes: [UInt8] = [channel1NoteOn, note, velocity]
            noteBlock(AUEventSampleTimeImmediate, channel, cbytes.count, cbytes)
        }

        // Finally, stop playing A4
        let noteOff = DispatchWorkItem(qos: .userInitiated, flags: []) {
            guard !sequence.isCancelled else { logCancel(); return }
            os_log(.error, log: self.log, "sending A4 OFF")
            let cbytes: [UInt8] = [channel1NoteOff, note, 0]
            noteBlock(AUEventSampleTimeImmediate, 0, cbytes.count, cbytes)
        }

        // Link commands together with appropriate delays.
        sequence.notify(queue: playingQueue) {
            guard !sequence.isCancelled else { logCancel(); return }
            os_log(.error, log: self.log, "all notes off done")
            self.playingQueue.asyncAfter(deadline: .now() + 0.1, execute: noteOn)
        }

        noteOn.notify(queue: playingQueue) {
            guard !sequence.isCancelled else { logCancel(); return }
            os_log(.error, log: self.log, "A4 ON done")
            self.playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)
        }

        workItem?.cancel()
        workItem = sequence
        playingQueue.asyncAfter(deadline: .now() + 0.1, execute: sequence)
    }
}
