// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import os

/**
 Enumeration of MIDI messages (v1.0) that will be sent to a MIDIController
 */
public enum MIDIMsg {
    case noteOff(note: UInt8, velocity: UInt8)
    case noteOn(note: UInt8, velocity: UInt8)
    case polyphonicKeyPressure(note: UInt8, pressure: UInt8)
    case controlChange(controller: UInt8, value: UInt8)
    case programChange(program: UInt8)
    case channelPressure(pressure: UInt8)
    case pitchBendChange(value: UInt16)
}

/**
 MIDIPacketList parser that generates MIDIMsg entities for the bytes in the packets.
 */
public struct MIDIParser {
    static private let log = Logging.logger("MIDIParser")

    public static func processPackets(controller: MIDIController, packetList: MIDIPacketList) {
        let numPackets = packetList.numPackets
        os_log(.info, log: log, "processPackets - %d", numPackets)
        var packet: MIDIPacket = packetList.packet
        var msgs = [MIDIMsg]()
        for index in 0..<numPackets {
            os_log(.info, log: log, "packet %d - %d bytes", index, packet.length)
            // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with really zero or really big sizes of 26624
            if packet.length == 0 || packet.length > 30 {
                os_log(.error, log: log, "suspect packet size %d", packet.length)
                break
            }
            msgs += processPacket(packet, controller)
            packet = MIDIPacketNext(&packet).pointee
        }
        DispatchQueue.global(qos: .userInteractive).async { controller.process(msgs) }
    }

    private enum MsgKind: UInt8 {
        case noteOff               = 0x80
        case noteOn                = 0x90
        case polyphonicKeyPressure = 0xA0
        case controlChange         = 0xB0 // also channelMode messages
        case programChange         = 0xC0
        case channelPressure       = 0xD0
        case pitchBendChange       = 0xE0
        case systemExclusive       = 0xF0
        case midiTimeCode          = 0xF1
        case songPosition          = 0xF2
        case songSelect            = 0xF3
        case tuneRequest           = 0xF6
        case endSystemExclusive    = 0xF7
        case timingClock           = 0xF8
        case sequenceStart         = 0xFA
        case sequenceContinue      = 0xFB
        case sequenceStop          = 0xFC
        case activeSensing         = 0xFE
        case reset                 = 0xFF

        init?(_ value: UInt8) {
            let command = value & 0xF0
            self.init(rawValue: command == 0xF0 ? value : command)
        }

        var hasChannel: Bool { self.rawValue < 0xF0 }
    }

    static private let msgSizes: [MsgKind: Int] = [
        .noteOff: 2,
        .noteOn: 2,
        .polyphonicKeyPressure: 2,
        .controlChange: 2,
        .programChange: 1,
        .channelPressure: 1,
        .pitchBendChange: 2,
        .midiTimeCode: 1,
        .songPosition: 2,
        .songSelect: 1
    ]

    static private let msgNames: [MsgKind: String] = [
        .noteOff: "noteOff",
        .noteOn: "noteOn",
        .polyphonicKeyPressure: "polyphonicKeyPressure",
        .controlChange: "controlChange",
        .programChange: "programChange",
        .channelPressure: "channelPressure",
        .pitchBendChange: "pitchBendChange",
        .systemExclusive: "systemExclusive",
        .midiTimeCode: "midiTimeCode",
        .songPosition: "songPosition",
        .songSelect: "songSelect",
        .tuneRequest: "tuneRequest",
        .endSystemExclusive: "endSystemExclusive",
        .timingClock: "timingClock",
        .sequenceStart: "sequenceStart",
        .sequenceContinue: "sequenceContinue",
        .sequenceStop: "sequenceStop",
        .activeSensing: "activeSensing",
        .reset: "reset"
    ]

    static private func msgPayloadSize(for kind: MsgKind) -> Int { msgSizes[kind] ?? 0 }

    private struct Pos {
        private var ptr: UnsafeRawBufferPointer
        public let count: Int
        private var index: Int = 0

        var available: Int { max(count - index, 0) }

        init(ptr: UnsafeRawBufferPointer, count: Int) {
            self.ptr = ptr
            self.index = 0
            self.count = count
        }

        mutating func next() -> UInt8 {
            precondition(index < count)
            defer { index = index + 1 }
            return ptr[index]
        }

        mutating func consume(_ amount: Int) { index += min(amount, available) }
    }

    private static func processPacket(_ packet: MIDIPacket, _ controller: MIDIController) -> [MIDIMsg] {
        let count = Int(packet.length)
        var msgs = [MIDIMsg]()
        os_log(.info, log: log, "processPacket - %d bytes", count)
        withUnsafeBytes(of: packet.data) { ptr in
            var pos = Pos(ptr: ptr, count: count)
            while pos.available > 0 {
                if let msg = processMessage(&pos, controller) {
                    msgs.append(msg)
                }
            }
        }
        return msgs
    }

    private static func processMessage(_ pos: inout Pos, _ controller: MIDIController) -> MIDIMsg? {
        let status = pos.next()
        guard let command = MsgKind(status) else { return nil }
        let needed = msgPayloadSize(for: command)

        os_log(.debug, log: log, "processMessage - %d %d", command.rawValue, needed)
        if needed > pos.available {
            pos.consume(pos.available)
            return nil
        }

        let channel = status & 0x0F
        if controller.accepted(channel) {
            if let msg = processMessage(&pos, command, controller) {
                return msg
            }
        }

        pos.consume(needed)
        return nil
    }

    private static func processMessage(_ pos: inout Pos, _ command: MsgKind, _ controller: MIDIController) -> MIDIMsg? {
        switch command {
        case .noteOff:
            let note = pos.next()
            let velocity = pos.next()
            return .noteOff(note: note, velocity: velocity)

        case .noteOn:
            let note = pos.next()
            let velocity = pos.next()
            return .noteOn(note: note, velocity: velocity)

        case .polyphonicKeyPressure:
            let note = pos.next()
            let pressure = pos.next()
            return .polyphonicKeyPressure(note: note, pressure: pressure)

        case .controlChange:
            let ctl = pos.next()
            let value = pos.next()
            return .controlChange(controller: ctl, value: value)

        case .programChange:
            let program = pos.next()
            return .programChange(program: program)

        case .channelPressure:
            let pressure = pos.next()
            return .channelPressure(pressure: pressure)

        case .pitchBendChange:
            let lsb = pos.next()
            let msb = pos.next()
            return .pitchBendChange(value: UInt16(msb) << 7 + UInt16(lsb))

        default: break
        }

        return nil
    }
}
