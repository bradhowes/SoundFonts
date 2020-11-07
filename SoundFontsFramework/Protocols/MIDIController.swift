// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import CoreMIDI

public protocol MIDIController: class {

    // The channel the controller listens on. If -1, then it receives ALL channels
    var channel: Int { get }

    func noteOff(note: UInt8, velocity: UInt8)
    func noteOn(note: UInt8, velocity: UInt8)
    func polyphonicKeyPressure(note: UInt8, pressure: UInt8)
    func controllerChange(controller: UInt8, value: UInt8)
    func programChange(program: UInt8)
    func channelPressure(pressure: UInt8)
    func pitchBend(value: UInt16)
}

extension MIDIController {

    public func processMessage(packet: MIDIPacket) {
        let status = packet.data.0
        if self.channel != -1 && self.channel != (status & 0x0F) { return }

        switch status & 0xF0 {
        case 0x80: noteOff(note: packet.data.1, velocity: packet.data.2)
        case 0x90: noteOn(note: packet.data.1, velocity: packet.data.2)
        case 0xA0: polyphonicKeyPressure(note: packet.data.1, pressure: packet.data.2)
        case 0xB0: controllerChange(controller: packet.data.1, value: packet.data.2)
        case 0xC0: programChange(program: packet.data.1)
        case 0xD0: channelPressure(pressure: packet.data.1)
        case 0xE0: pitchBend(value: UInt16(packet.data.2) * 256 + UInt16(packet.data.1))
        default: break
        }
    }
}
