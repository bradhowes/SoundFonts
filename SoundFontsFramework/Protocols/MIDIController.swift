// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import CoreMIDI

public protocol MIDIController: class {

    // The channel the controller listens on. If -1, then it receives ALL channels
    var channel: Int { get }

    func noteOff(note: UInt8)
    func noteOn(note: UInt8, velocity: UInt8)
    func polyphonicKeyPressure(note: UInt8, pressure: UInt8)
    func controlChange(controller: UInt8, value: UInt8)
    func programChange(program: UInt8)
    func channelPressure(pressure: UInt8)
    func pitchBendChange(value: UInt16)
}

extension MIDIController {
    public func accepted(_ channel: UInt8) -> Bool { self.channel == -1 || self.channel == channel }

    public func process(_ msgs: [MIDIMsg]) {
        for msg in msgs {
            switch msg {
            case let .noteOff(note, _): self.noteOff(note: note)
            case let .noteOn(note, velocity): self.noteOn(note: note, velocity: velocity)
            case let .polyphonicKeyPressure(note, pressure): self.polyphonicKeyPressure(note: note, pressure: pressure)
            case let .controlChange(controller, value): self.controlChange(controller: controller, value: value)
            case let .programChange(program): self.programChange(program: program)
            case let .channelPressure(pressure): self.channelPressure(pressure: pressure)
            case let .pitchBendChange(value): self.pitchBendChange(value: value)
            }
        }
    }
}
