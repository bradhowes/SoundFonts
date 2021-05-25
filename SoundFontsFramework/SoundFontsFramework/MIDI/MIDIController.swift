// Copyright © 2020 Brad Howes. All rights reserved.

import os

public final class MIDIController {
    private lazy var log = Logging.logger("MIDIController")

    public private(set) var channel: Int

    private let sampler: Sampler
    private let keyboard: Keyboard?
    private var observer: NSKeyValueObservation?

    public init(sampler: Sampler, keyboard: Keyboard?) {
        self.sampler = sampler
        self.keyboard = keyboard
        self.channel = Settings.shared.midiChannel
        self.observer = Settings.shared.observe(\.midiChannel) { [weak self] _, _ in
            guard let self = self else { return }
            let value = Settings.shared.midiChannel
            if value != self.channel {
                os_log(.info, log: self.log, "new MIDI channel: %d", value)
                self.channel = value
            }
        }
    }
}

extension MIDIController: MIDIReceiver {

    public func noteOff(note: UInt8) {
        sampler.noteOff(note)
        keyboard?.noteIsOff(note: note)
    }

    public func noteOn(note: UInt8, velocity: UInt8) {
        sampler.noteOn(note, velocity: velocity)
        keyboard?.noteIsOn(note: note)
    }

    public func releaseAllKeys() {
        keyboard?.releaseAllKeys()
    }

    public func polyphonicKeyPressure(note: UInt8, pressure: UInt8) {
        sampler.polyphonicKeyPressure(note, pressure: pressure)
    }

    public func channelPressure(pressure: UInt8) {
        sampler.channelPressure(pressure)
    }

    public func pitchBendChange(value: UInt16) {
        sampler.pitchBendChange(value)
    }

    public func controlChange(controller: UInt8, value: UInt8) {
        sampler.controlChange(controller, value: value)
    }

    public func programChange(program: UInt8) {
        sampler.programChange(program)
    }
}
