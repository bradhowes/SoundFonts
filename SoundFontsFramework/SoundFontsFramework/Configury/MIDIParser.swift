// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import os

/// Enumeration of MIDI messages (v1.0) that will be sent to a MIDIController
public enum MIDIMsg {
  case noteOff(note: UInt8, velocity: UInt8)
  case noteOn(note: UInt8, velocity: UInt8)
  case polyphonicKeyPressure(note: UInt8, pressure: UInt8)
  case controlChange(controller: UInt8, value: UInt8)
  case programChange(program: UInt8)
  case channelPressure(pressure: UInt8)
  case pitchBendChange(value: UInt16)
}

/// MIDIPacketList parser that generates MIDIMsg entities for the bytes in the packets and forwards them to a
/// MIDIController
public struct MIDIParser {
  static private let log = Logging.logger("MIDIParser")
  private var log: OSLog { Self.log }

  /**
   Extract MIDI messages and send to controller.

   - parameter packetList: the MIDI data to parse
   - parameter controller: the recipient of the MIDI messages
   */
  public static func parse(packetList: MIDIPacketList, for controller: MIDIReceiver) {
    os_signpost(.begin, log: log, name: "parse")
    let numPackets = packetList.numPackets
    os_log(.info, log: log, "processPackets - %d channel: %d", numPackets, controller.channel)
    var packet: MIDIPacket = packetList.packet
    for index in 0..<numPackets {
      let when = packet.timeStamp
      let length = Int(packet.length)
      os_log(.debug, log: log, "packet %d - %ld %d bytes", index, when, length)

      // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with zero or really big
      // sizes of 26624 (0x6800!)
      if length == 0 || length > 64 {
        os_log(.error, log: log, "suspect packet size %d", length)
        break
      }

      // Send all MIDI messages in one packet at once to a MIDI controller
      withUnsafeBytes(of: packet.data) { ptr in
        let msgs = Generator(ptr: ptr, count: length, channel: controller.channel).messages
        if !msgs.isEmpty {
          os_signpost(.begin, log: log, name: "sendToController")
          controller.process(msgs, when: when)
          os_signpost(.end, log: log, name: "sendToController")
        }
      }
      packet = MIDIPacketNext(&packet).pointee
    }
    os_signpost(.end, log: log, name: "parse")
  }

  private enum MsgKind: UInt8 {
    case noteOff = 0x80
    case noteOn = 0x90
    case polyphonicKeyPressure = 0xA0
    case controlChange = 0xB0  // also channelMode messages
    case programChange = 0xC0
    case channelPressure = 0xD0
    case pitchBendChange = 0xE0
    case systemExclusive = 0xF0
    case midiTimeCode = 0xF1
    case songPosition = 0xF2
    case songSelect = 0xF3
    case tuneRequest = 0xF6
    case endSystemExclusive = 0xF7
    case timingClock = 0xF8
    case sequenceStart = 0xFA
    case sequenceContinue = 0xFB
    case sequenceStop = 0xFC
    case activeSensing = 0xFE
    case reset = 0xFF

    init?(_ raw: UInt8) {
      let highNibble = raw & 0xF0
      self.init(rawValue: highNibble == 0xF0 ? raw : highNibble)
    }
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

  private struct Generator: Sequence, IteratorProtocol {
    private var ptr: UnsafeRawBufferPointer
    private let count: Int
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
      let status = ptr[index]
      consume(1)
      guard let command = MsgKind(status) else { return nil }
      let needed = msgSizes[command] ?? 0
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
      case .polyphonicKeyPressure:
        return .polyphonicKeyPressure(note: ptr[index], pressure: ptr[index + 1])
      case .controlChange: return .controlChange(controller: ptr[index], value: ptr[index + 1])
      case .programChange: return .programChange(program: ptr[index])
      case .channelPressure: return .channelPressure(pressure: ptr[index])
      case .pitchBendChange:
        return .pitchBendChange(value: UInt16(ptr[index + 1]) << 7 + UInt16(ptr[index]))
      default: break
      }
      return nil
    }

    mutating private func consume(_ amount: Int) { index += Swift.min(amount, available) }
  }
}
