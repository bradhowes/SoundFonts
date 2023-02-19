import CoreMIDI
import os

private let log = Logging.logger("MIDIPacketList")

/// Allow iterating over the packets in a MIDIPacketList
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
   Extract MIDI messages from the packets and process them

   - parameter receiver: optional entity to process MIDI messages
   - parameter monitor: optional entity to monitor MIDI traffic
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
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

extension MIDIPacketList {

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

extension MIDIPacket {

  /**
   Builder of MIDIPacket instances from a collection of UInt8 values
   */
  public struct Builder {

    /// The timestamp for all of the MIDI events recorded in the data
    public let timestamp: MIDITimeStamp
    private var data = [UInt8]()

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter data: the initial data to record
     */
    public init(timestamp: MIDITimeStamp, data: [UInt8] = []) {
      self.timestamp = timestamp
      self.data = data
    }

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter msg: the MIDI command to add
     */
    public init(timestamp: MIDITimeStamp, msg: MIDI1Msg) {
      self.timestamp = timestamp
      self.data = [msg.rawValue]
    }

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter msg: the MIDI command to add
     - parameter data1: the first data value
     */
    public init(timestamp: MIDITimeStamp, msg: MIDI1Msg, data1: UInt8) {
      self.timestamp = timestamp
      self.data = [msg.rawValue, data1]
    }

    /**
     Create a new builder

     - parameter timestamp: the timestamp for all of the events in the packet
     - parameter msg: the MIDI command to add
     - parameter data1: the first data value
     - parameter data2: the second data value
     */
    public init(timestamp: MIDITimeStamp, msg: MIDI1Msg, data1: UInt8, data2: UInt8) {
      self.timestamp = timestamp
      self.data = [msg.rawValue, data1, data2]
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(data: [UInt8]) {
      self.data.append(contentsOf: data)
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(msgKind: MIDI1Msg) {
      self.data.append(msgKind.rawValue)
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
   public mutating func add(msgKind: MIDI1Msg, data1: UInt8) {
      self.data.append(contentsOf: [msgKind.rawValue, data1])
    }

    /**
     Add additional MID commands to the current collection

     - parameter data: MIDI data to add to the packet
     */
    public mutating func add(msgKind: MIDI1Msg, data1: UInt8, data2: UInt8) {
      self.data.append(contentsOf: [msgKind.rawValue, data1, data2])
    }

    /// Obtain a MIDIPacket from the MIDI data collection.
    public var packet: MIDIPacket {
      var packet = MIDIPacket()
      precondition(data.count <= 256)
      packet.timeStamp = timestamp
      packet.length = UInt16(data.count)
      withUnsafeMutableBytes(of: &packet.data) { $0.copyBytes(from: data) }
      return packet
    }
  }
}

extension MIDIPacket {

  /// MIDIPacket instances must be aligned on 4-byte boundaries. Obtain the packet size + any padding to stay aligned
  var alignedByteSize: Int {
    ((MemoryLayout<MIDITimeStamp>.size + MemoryLayout<UInt16>.size + Int(self.length) + 3) / 4) * 4
  }

  /**
   Extract MIDI messages from the packets and process them

   - parameter receiver: optional entity to process MIDI messages
   - parameter monitor: optional entity to monitor MIDI traffic
   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the messages
   */
  func parse(midi: MIDI, receiver: AnyMIDIReceiver?, monitor: MIDIActivityNotifier, endpoint: MIDIEndpointRef) {
    let byteCount = Int(self.length)

    // Uff. In testing with Arturia Minilab mk II, I can sometimes generate packets with zero or really big
    // sizes of 26624 (0x6800!)
    if byteCount == 0 || byteCount > 64 {
      os_log(.error, log: log, "suspect packet size %d", byteCount)
      return
    }

    os_log(.debug, log: log, "packet - %ld %d bytes", timeStamp, byteCount)

    // Visit the individual bytes until all consumed. If there is something we don't understand, we stop processing the
    // packet.
    withUnsafeBytes(of: self.data) { ptr in
      var index: Int = 0
      var runningStatus: UInt8 = 0

      while index < byteCount {
        var status = ptr[index]
        index += 1

        let command: MIDI1Msg
        if let tmp = MIDI1Msg(status) {
          command = tmp
          runningStatus = command.hasChannel ? status : 0
        } else if let tmp = MIDI1Msg(runningStatus) {
          command = tmp
          status = runningStatus
          index -= 1
        } else {
          os_log(.error, log: log, "packet - missing command")
          return
        }

        let channel = command.hasChannel ? status.nibbleLow : 0

        // We have enough information to update the channel that an endpoint is sending on
        if command.hasChannel {
          midi.updateChannel(endpoint: endpoint, channel: channel)
        }

        let needed = command.byteCount

        os_log(.debug, log: log, "message: %d packetChannel: %d needed: %d", command.rawValue, channel, needed)

        // Not enough bytes to continue on
        guard index + needed <= byteCount else {
          os_log(.error, log: log, "packet - not enough bytes to continue")
          return
        }

        if let receiver = receiver {
          func note() -> UInt8 { ptr[index] }
          func velocity() -> UInt8 { ptr[index + 1] }

          switch command {
          case .noteOff:
            receiver.stopNote(note: note(), velocity: 0, channel: channel)
          case .noteOn:
            let vel = velocity()
            if vel == 0 {
              receiver.stopNote(note: note(), velocity: 0, channel: channel)
            } else {
              receiver.startNote(note: note(), velocity: vel, channel: channel)
            }
          case .polyphonicKeyPressure:
            receiver.setNotePressure(note: note(), pressure: velocity(), channel: channel)
          case .controlChange:
            let id = ptr[index]
            let value = ptr[index + 1]
            receiver.setController(controller: id, value: value, channel: channel)
          case .programChange:
            receiver.changeProgram(program: ptr[index], channel: channel)
          case .channelPressure:
            receiver.setPressure(pressure: ptr[index], channel: channel)
          case .pitchBendChange:
            let value = UInt16(ptr[index + 1]) << 7 + UInt16(ptr[index])
            receiver.setPitchBend(value: value, channel: channel)
          case .systemExclusive: break
          case .timeCodeQuarterFrame: break
          case .songPositionPointer: break
          case .songSelect: break
          case .tuneRequest: break
          case .timingClock: break
          case .startCurrentSequence: break
          case .continueCurrentSequence: break
          case .stopCurrentSequence: break
          case .activeSensing: break
          case .reset: receiver.stopAllNotes()
          }
        }

        monitor.showActivity(endpoint: endpoint, channel: Int(channel))

        index += needed
      }
    }
  }
}
