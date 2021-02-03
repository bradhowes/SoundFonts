// Copyright © 2020 Brad Howes. All rights reserved.

import os

public final class MIDIController {
    private lazy var log = Logging.logger("MIDIController")

    public var channel: Int { Settings.shared.midiChannel }

    private let sampler: Sampler
    private let keyboard: Keyboard?

    public init(sampler: Sampler, keyboard: Keyboard?) {
        self.sampler = sampler
        self.keyboard = keyboard
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
