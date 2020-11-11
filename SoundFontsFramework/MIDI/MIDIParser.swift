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
        os_log(.debug, log: log, "processPackets - %d", numPackets)
        var packet: MIDIPacket = packetList.packet
        for index in 0..<numPackets {
            os_log(.info, log: log, "packet %d - %d bytes", index, packet.length)
            // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with really zero or really big sizes of 26624
            if packet.length == 0 || packet.length > 64 {
                os_log(.error, log: log, "suspect packet size %d", packet.length)
                break
            }
            parsePacket(packet, controller)
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    private static func parsePacket(_ packet: MIDIPacket, _ controller: MIDIController) {
        let when = packet.timeStamp
        let count = Int(packet.length)
        os_log(.debug, log: log, "processPacket - %ld %d bytes", when, count)

        // Send all MIDI messages in one packet at once to a MIDI controller
        withUnsafeBytes(of: packet.data) { ptr in
            let msgs = Generator(ptr: ptr, count: count, channel: controller.channel).messages
            if !msgs.isEmpty {
                DispatchQueue.global(qos: .userInitiated).async { controller.process(msgs) }
            }
        }
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

    private struct Generator: Sequence, IteratorProtocol {
        typealias Element = MIDIMsg

        private let log = Logging.logger("MIDIParser.Pos")

        private var ptr: UnsafeRawBufferPointer
        public let count: Int
        private var index: Int = 0
        private let channel: Int

        private var available: Int { Swift.max(count - index, 0) }

        var messages: [MIDIMsg] { [MIDIMsg](self) }

        init(ptr: UnsafeRawBufferPointer, count: Int, channel: Int) {
            self.ptr = ptr
            self.count = count
            self.channel = channel
        }

        func makeIterator() -> Self { self }

        mutating func next() -> MIDIMsg? {
            guard available > 0 else { return nil }
            return parseMIDIMsg() ?? next()
        }

        mutating private func parseMIDIMsg() -> MIDIMsg? {
            let status = pop()
            guard let command = MsgKind(status) else { return nil }
            let needed = msgPayloadSize(for: command)

            if needed > available {
                consume(available)
                return nil
            }

            defer { consume(needed) }
            return (channel == -1 || channel == (status & 0x0F)) ? makeMIDIMsg(command) : nil
        }

        mutating private func makeMIDIMsg(_ command: MsgKind) -> MIDIMsg? {
            switch command {
            case .noteOff: return .noteOff(note: ptr[index], velocity: ptr[index + 1])
            case .noteOn: return .noteOn(note: ptr[index], velocity: ptr[index + 1])
            case .polyphonicKeyPressure: return .polyphonicKeyPressure(note: ptr[index], pressure: ptr[index + 1])
            case .controlChange: return .controlChange(controller: ptr[index], value: ptr[index + 1])
            case .programChange: return .programChange(program: ptr[index])
            case .channelPressure: return .channelPressure(pressure: ptr[index])
            case .pitchBendChange: return .pitchBendChange(value: UInt16(ptr[index + 1]) << 7 + UInt16(ptr[index]))
            default: break
            }
            return nil
        }

        mutating private func pop() -> UInt8 {
            precondition(index < count)
            defer { consume(1) }
            return ptr[index]
        }

        mutating private func consume(_ amount: Int) { index += Swift.min(amount, available) }
    }
}
