// Copyright © 2020 Brad Howes. All rights reserved.

import os
import CoreAudioKit

public final class NoteInjector {
    private let log = Logging.logger("NoInj")
    private let playingQueue = DispatchQueue(label: "NoteInjector.playingQueue", qos: .userInitiated)
    private var workItems = [DispatchWorkItem]()

    private let note = 69 // A4
    private let noteOnDuration = 1.0

    public init() {}

    public func post(to sampler: Sampler) {
        guard Settings[.playSample] == true else { return }
        let note = self.note
        let noteOnDuration = self.noteOnDuration

        let noteOn = DispatchWorkItem { sampler.noteOn(note, velocity: 32) }
        playingQueue.asyncAfter(deadline: .now() + 0.1, execute: noteOn)

        let noteOff = DispatchWorkItem { sampler.noteOff(note) }
        playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)

        workItems.forEach { $0.cancel() }
        workItems = [noteOn, noteOff]
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
        playingQueue.async(execute: noteOn)

        let noteOff = DispatchWorkItem {
            let cbytes: [UInt8] = [channel1NoteOn, note, 0]
            noteBlock(AUEventSampleTimeImmediate, 0, cbytes.count, cbytes)
        }
        playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)

        workItems.forEach { $0.cancel() }
        workItems = [noteOn, noteOff]
    }
}
