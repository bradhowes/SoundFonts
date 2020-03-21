// Copyright © 2020 Brad Howes. All rights reserved.

import os
import CoreAudioKit

public final class NoteInjector {
    private let log = Logging.logger("NoInj")
    private let playingQueue = DispatchQueue(label: "NoteInjector.playingQueue", qos: .userInitiated)
    private var workItems: [DispatchWorkItem]()

    private let note = 69 // A4
    private let noteOnDuration = 0.7

    public init() {}

    public func post(to sampler: Sampler) {
        guard Settings[.playSample] == true else { return }
        let note = self.note
        let noteOnDuration = self.noteOnDuration

        let noteOn = DispatchWorkItem { sampler.noteOn(note) }
        let noteOff = DispatchWorkItem { sampler.noteOff(note) }

        noteOn.notify(queue: playingQueue) {
            self.playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)
        }

        workItems.forEach { $0.cancel() }
        workItems = [noteOn, noteOff]

        playingQueue.async(execute: noteOn)
    }

    public func post(to audioUnit: AUAudioUnit) {
        guard Settings[.playSample] == true else { return }

        guard let noteBlock = audioUnit.scheduleMIDIEventBlock else { return }
        os_log(.error, log: log, "post - valid noteBlock")

        let channel: UInt8 = 0
        let channel1NoteOn: UInt8 = 0x90

        let note = UInt8(self.note)
        let noteOnDuration = 1.0
        let velocity: UInt8 = 64

        let noteOn = DispatchWorkItem {
            let cbytes: [UInt8] = [channel1NoteOn, note, velocity]
            noteBlock(AUEventSampleTimeImmediate, channel, cbytes.count, cbytes)
        }

        let noteOff = DispatchWorkItem {
            let cbytes: [UInt8] = [channel1NoteOn, note, 0]
            noteBlock(AUEventSampleTimeImmediate, 0, cbytes.count, cbytes)
        }

        noteOn.notify(queue: playingQueue) {
            self.playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)
        }

        workItems.forEach { $0.cancel() }
        workItems = [noteOn, noteOff]

        playingQueue.async(execute: noteOn)
    }
}
