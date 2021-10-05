import CoreMIDI
import os

private let log = Logging.logger("MIDIPacketList")

extension MIDIPacketList: Sequence {
  public typealias Element = MIDIPacket

  public var count: UInt32 { self.numPackets }

  public func makeIterator() -> AnyIterator<Element> {
    var current: MIDIPacket = packet
    var index: UInt32 = 0
    return AnyIterator {
      guard index < self.numPackets else { return nil }
      defer {
        current = MIDIPacketNext(&current).pointee
        index += 1
      }
      return current
    }
  }

  /**
   Extract MIDI messages and send to MIDI receiver.

   - parameter receiver: entity receiving MIDI messages
   */
  func parse(receiver: MIDIReceiver?, monitor: MIDIMonitor?, uniqueId: MIDIUniqueID) {
    os_signpost(.begin, log: log, name: "parse")
    os_log(.info, log: log, "processPackets - %d", numPackets)
    for packet in self {
      os_signpost(.begin, log: log, name: "sendToController")
      packet.parse(receiver: receiver, monitor: monitor, uniqueId: uniqueId)
      os_signpost(.end, log: log, name: "sendToController")
    }
    os_signpost(.end, log: log, name: "parse")
  }
}

extension MIDIPacket {

  /**
   Parse a MIDIPacket bytes, extracting MIDI messages and sending them to a MIDI receiver

   - parameter receiver: entity receiving MIDI messages
   */
  func parse(receiver: MIDIReceiver?, monitor: MIDIMonitor?, uniqueId: MIDIUniqueID) {
    let byteCount = Int(self.length)

    // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with zero or really big
    // sizes of 26624 (0x6800!)
    if byteCount == 0 || byteCount > 64 {
      os_log(.error, log: log, "suspect packet size %d", byteCount)
      return
    }

    os_log(.debug, log: log, "packet - %ld %d bytes", timeStamp, byteCount)

    withUnsafeBytes(of: self.data) { ptr in
      var index: Int = 0
      func available() -> Int { Swift.max(byteCount - index, 0) }

      let receiverChannel = receiver?.channel ?? -2
      while available() > 0 {
        let status = ptr[index]
        index += Swift.min(1, available())

        guard let command = MsgKind(status) else { continue }

        let needed = command.byteCount
        let packetChannel = Int(status & 0x0F)

        MIDI.sharedInstance.updateChannel(uniqueId: uniqueId, channel: packetChannel)

        os_log(.debug, log: log, "message: %d packetChannel: %d needed: %d", command.rawValue, packetChannel, needed)

        if let monitor = monitor {
          monitor.seen(uniqueId: uniqueId)
        }

        guard needed <= available() && (receiverChannel == -1 || receiverChannel == packetChannel) else {
          index += Swift.min(needed, available())
          continue
        }

        if let receiver = receiver {
          switch command {
          case .noteOff: receiver.noteOff(note: ptr[index])
          case .noteOn: receiver.noteOn(note: ptr[index], velocity: ptr[index + 1])
          case .polyphonicKeyPressure: receiver.polyphonicKeyPressure(note: ptr[index], pressure: ptr[index + 1])
          case .controlChange: receiver.controlChange(controller: ptr[index], value: ptr[index + 1])
          case .programChange: receiver.programChange(program: ptr[index])
          case .channelPressure: receiver.channelPressure(pressure: ptr[index])
          case .pitchBendChange: receiver.pitchBendChange(value: UInt16(ptr[index + 1]) << 7 + UInt16(ptr[index]))
          }
        }
        index += Swift.min(needed, available())
      }
    }
  }
}

/// These are the only MIDI messages we support
private enum MsgKind: UInt8 {
  case noteOff = 0x80
  case noteOn = 0x90
  case polyphonicKeyPressure = 0xA0
  case controlChange = 0xB0  // also channelMode messages
  case programChange = 0xC0
  case channelPressure = 0xD0
  case pitchBendChange = 0xE0

  init?(_ raw: UInt8) {
    let highNibble = raw & 0xF0
    self.init(rawValue: highNibble == 0xF0 ? raw : highNibble)
  }

  var byteCount: Int {
    switch self {
    case .noteOff: return 2
    case .noteOn: return 2
    case .polyphonicKeyPressure: return 2
    case .controlChange: return 2
    case .programChange: return 1
    case .channelPressure: return 1
    case .pitchBendChange: return 2
    }
  }
}
