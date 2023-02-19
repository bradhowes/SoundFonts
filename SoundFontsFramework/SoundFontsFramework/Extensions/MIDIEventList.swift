import CoreMIDI
import os

private let log = Logging.logger("MIDIEventList")

/// Allow iterating over the packets in a MIDIPacketList
extension MIDIEventList: Sequence {
  public typealias Element = MIDIEventPacket

  public var count: UInt32 { self.numPackets }

  public func makeIterator() -> AnyIterator<Element> {
    var current: MIDIEventPacket = packet
    var index: UInt32 = 0
    return AnyIterator {
      guard index < self.numPackets else { return nil }
      defer {
        current = MIDIEventPacketNext(&current).pointee
        index += 1
      }
      return current
    }
  }

  /**
   Extract MIDI messages from the events and process them

   - parameter receiver: optional entity to process MIDI messages
   - parameter monitor: optional entity to monitor MIDI traffic
   - parameter endpoint: the MIDI endpoint that sent the messages
   */
  public func parse(midi: MIDI, receiver: AnyMIDIReceiver?, monitor: MIDIActivityNotifier, endpoint: MIDIEndpointRef) {
    os_signpost(.begin, log: log, name: "parse")
    os_log(.debug, log: log, "processPackets - %d", numPackets)
    for packet in self {
      os_signpost(.begin, log: log, name: "sendToController")
      packet.parse(midi: midi, receiver: receiver, monitor: monitor, endpoint: endpoint)
      os_signpost(.end, log: log, name: "sendToController")
    }
    os_signpost(.end, log: log, name: "parse")
  }
}

extension MIDIEventList {

  /**
   Builder of MIDIPacketList instances from a collection of MIDIPacket entities
   */
  public struct Builder {

    private var packets = [MIDIPacket]()

    /**
     Add a MIDIPacket to the collection

     - parameter packet: the MIDIPacket to add
     */
    public mutating func add(packet: MIDIPacket) { packets.append(packet) }

    /// Obtain a MIDIPacketList from the MIDIPacket collection
    public var packetList: MIDIPacketList {

      let packetsSize = (packets.map { $0.alignedByteSize }).reduce(0, +)
      let listSize = MemoryLayout<MIDIPacketList>.size - MemoryLayout<MIDIPacket>.size + packetsSize

      func optionalMIDIPacketListAdd(_ packetListPtr: UnsafeMutablePointer<MIDIPacketList>,
                                     _ curPacketPtr: UnsafeMutablePointer<MIDIPacket>,
                                     _ packet: MIDIPacket) -> UnsafeMutablePointer<MIDIPacket>? {
        return withUnsafeBytes(of: packet.data) { ptr in
          return MIDIPacketListAdd(packetListPtr, listSize, curPacketPtr, packet.timeStamp,
                                   Int(packet.length), ptr.bindMemory(to: UInt8.self).baseAddress!)
        }
      }

      // Build the MIDIPacketList in the memory allocated by Data and then take it over
      var buffer = Data(count: listSize)
      return buffer.withUnsafeMutableBytes { (bufferPtr: UnsafeMutableRawBufferPointer) -> MIDIPacketList in
        let packetListPtr = bufferPtr.bindMemory(to: MIDIPacketList.self).baseAddress!
        var curPacketPtr = MIDIPacketListInit(packetListPtr)
        for packet in packets {
          guard let newPacketPtr = optionalMIDIPacketListAdd(packetListPtr, curPacketPtr, packet) else {
            fatalError()
          }
          curPacketPtr = newPacketPtr
        }
        return packetListPtr.move()
      }
    }
  }
}

extension MIDIEventPacket {

  /// These are the only MIDI messages we support for now.saf
  public enum MsgKind: UInt8 {
    case noteOff = 0x80
    case noteOn = 0x90
    case polyphonicKeyPressure = 0xA0
    case controlChange = 0xB0
    case programChange = 0xC0
    case channelPressure = 0xD0
    case pitchBendChange = 0xE0
    case systemExclusive = 0xF0
    case timeCodeQuarterFrame = 0xF1
    case songPositionPointer = 0xF2
    case songSelect = 0xF3
    case tuneRequest = 0xF6
    case timingClock = 0xF8
    case startCurrentSequence = 0xFA
    case continueCurrentSequence = 0xFB
    case stopCurrentSequence = 0xFC
    case activeSensing = 0xFE
    case reset = 0xFF

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
      case .systemExclusive: return 65_537 // Make too large to put in MIDIPacket
      case .timeCodeQuarterFrame: return 1
      case .songPositionPointer: return 2
      case .songSelect: return 1
      case .tuneRequest: return 0
      case .timingClock: return 0
      case .startCurrentSequence: return 0
      case .continueCurrentSequence: return 0
      case .stopCurrentSequence: return 0
      case .activeSensing: return 0
      case .reset: return 0
      }
    }
  }
}

extension MIDIEventPacket {

  /**
   Extract MIDI messages from the packets and process them

   - parameter receiver: optional entity to process MIDI messages
   - parameter monitor: optional entity to monitor MIDI traffic
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(midi: MIDI, receiver: AnyMIDIReceiver?, monitor: MIDIActivityNotifier, endpoint: MIDIEndpointRef) {
    let byteCount = wordCount * 4

    if wordCount == 0 {
      os_log(.error, log: log, "suspect packet size %d", wordCount)
      return
    }

    os_log(.debug, log: log, "packet - %ld %d bytes", timeStamp, byteCount)

    // Visit the individual bytes until all consumed. If there is something we don't understand, we stop processing the
    // packet.
    withUnsafeBytes(of: self.words) { ptr in
      let data = Data(bytes: ptr.baseAddress!, count: Int(byteCount))
      os_log(.debug, log: log, "bytes: %{public}s", data.hexEncodedString())
      // monitor.showActivity(endpoint: endpoint, channel: Int(channel))
    }
  }
}

extension Data {
  func hexEncodedString() -> String {
    return self.map { String(format: "%02hhX", $0) }.joined(separator: " ")
  }
}
