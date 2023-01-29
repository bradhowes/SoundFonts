// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import CoreMIDI
import XCTest

class MIDIPacketTesting: XCTestCase {

  class Receiver: AnyMIDIReceiver {

    func stopAllNotes() {}
    func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {}
    func setController(controller: UInt8, value: UInt8, channel: UInt8) {}
    func changeProgram(program: UInt8, channel: UInt8) {}
    func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {}
    func setPressure(pressure: UInt8, channel: UInt8) {}
    func setPitchBend(value: UInt16, channel: UInt8) {}
    func processMIDIEvent(status: UInt8, data1: UInt8) {}
    func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {}

    struct Event: Equatable {
      let cmd: UInt8
      let data1: UInt8
      let data2: UInt8
    }

    var channel: Int = -1
    var received = [Event]()

    func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
      received.append(Event(cmd: 0x90, data1: note, data2: velocity))
    }

    func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
      received.append(Event(cmd: 0x80, data1: note, data2: velocity)) }
  }

  class Monitor: MIDIMonitor {
    var uniqueIds = [MIDIUniqueID: Set<UInt8>]()
    func seen(uniqueId: MIDIUniqueID, channel: UInt8) {
      print(uniqueId, channel)
      uniqueIds[uniqueId, default: .init()].insert(channel)
    }
  }

  func testBuilder() {
    let builder = MIDIPacket.Builder(timestamp: 123, data: [1, 2, 3])
    let packet = builder.packet
    XCTAssertEqual(packet.length, 3)
    XCTAssertEqual(packet.timeStamp, 123)
    XCTAssertEqual(packet.data.0, 1)
    XCTAssertEqual(packet.data.1, 2)
    XCTAssertEqual(packet.data.2, 3)
  }

  func testAdd() {
    var builder = MIDIPacket.Builder(timestamp: 456, data: [1, 2, 3])
    builder.add(data: [4, 5, 6, 7])
    builder.add(data: [])
    builder.add(data: [8])

    let packet = builder.packet
    XCTAssertEqual(packet.length, 8)
    XCTAssertEqual(packet.timeStamp, 456)
    XCTAssertEqual(packet.data.0, 1)
    XCTAssertEqual(packet.data.1, 2)
    XCTAssertEqual(packet.data.2, 3)
    XCTAssertEqual(packet.data.3, 4)
    XCTAssertEqual(packet.data.4, 5)
    XCTAssertEqual(packet.data.5, 6)
    XCTAssertEqual(packet.data.6, 7)
    XCTAssertEqual(packet.data.7, 8)
  }

  func testParser() {
    let receiver = Receiver()
    receiver.channel = -1 // OMNI mode
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32]).packet
    noteOn.parse(receiver: receiver, monitor: MIDIActivityNotifier(), uniqueId: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: 0x90, data1: 64, data2:32)])
  }

  func testParserReceivingOnChannelMatch() {
    let receiver = Receiver()
    receiver.channel = 1
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32]).packet
    noteOn.parse(receiver: receiver, monitor: MIDIActivityNotifier(), uniqueId: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: 0x90, data1: 64, data2: 32)])
  }

  func testParserSkippingUnknownMessage() {
    let receiver = Receiver()
    let bogus = MIDIPacket.Builder(timestamp: 0, data: [0xF4, 0x91, 64, 32]).packet
    bogus.parse(receiver: receiver, monitor: MIDIActivityNotifier(), uniqueId: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserSkippingIncompleteMessage() {
    let receiver = Receiver()
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64]).packet
    noteOn.parse(receiver: receiver, monitor: MIDIActivityNotifier(), uniqueId: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserMultipleMessages() {
    let receiver = Receiver()
    let noteOnOff = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet
    noteOnOff.parse(receiver: receiver, monitor: MIDIActivityNotifier(), uniqueId: 123)
    XCTAssertEqual(receiver.received, [
      Receiver.Event(cmd: 0x90, data1: 64, data2: 32),
      Receiver.Event(cmd: 0x80, data1: 64, data2: 0)
    ])
  }

  func testAlignments() {
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: []).packet.alignedByteSize, 12)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1]).packet.alignedByteSize, 12)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1, 2]).packet.alignedByteSize, 12)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1, 2, 3]).packet.alignedByteSize, 16)
    XCTAssertEqual(MIDIPacket.Builder(timestamp: 0, data: [1, 2, 3, 4]).packet.alignedByteSize, 16)
  }

  func testListBuilder() {
    let a = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet
    let b = MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x81, 66, 0]).packet

    var builder = MIDIPacketList.Builder()
    builder.add(packet: a)
    builder.add(packet: b)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)

    for (index, packet) in list.enumerated() {
      switch index {
      case 0:
        XCTAssertEqual(packet.timeStamp, 0)
        XCTAssertEqual(packet.length, 6)
        XCTAssertEqual(packet.data.0, 0x91)
        XCTAssertEqual(packet.data.1, 64)
        XCTAssertEqual(packet.data.2, 32)
        XCTAssertEqual(packet.data.3, 0x81)
        XCTAssertEqual(packet.data.4, 64)
        XCTAssertEqual(packet.data.5, 0)

      case 1:
        XCTAssertEqual(packet.timeStamp, 1)
        XCTAssertEqual(packet.length, 9)
        XCTAssertEqual(packet.data.0, 0x91)
        XCTAssertEqual(packet.data.1, 65)
        XCTAssertEqual(packet.data.2, 33)
        XCTAssertEqual(packet.data.3, 0x81)
        XCTAssertEqual(packet.data.4, 65)
        XCTAssertEqual(packet.data.5, 10)
        XCTAssertEqual(packet.data.6, 0x81)
        XCTAssertEqual(packet.data.7, 66)
        XCTAssertEqual(packet.data.8, 0)
      default: fatalError()
      }
    }
  }

  func testListsParsing() {
    let receiver = Receiver()

    var builder = MIDIPacketList.Builder()
    builder.add(packet: MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet)
    builder.add(packet: MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x81, 66, 0]).packet)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)
    list.parse(receiver: receiver, monitor: MIDIActivityNotifier(), uniqueId: 0)

    XCTAssertEqual(receiver.received, [
      Receiver.Event(cmd: 0x90, data1: 64, data2: 32),
      Receiver.Event(cmd: 0x80, data1: 64, data2: 0),
      Receiver.Event(cmd: 0x90, data1: 65, data2: 33),
      Receiver.Event(cmd: 0x80, data1: 65, data2: 10),
      Receiver.Event(cmd: 0x80, data1: 66, data2: 0)
    ])
  }

  func testMonitoringTraffic() {
    let monitor = MIDIActivityNotifier()

    var builder = MIDIPacketList.Builder()
    builder.add(packet: MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet)
    builder.add(packet: MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x82, 66, 0]).packet)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)

    let expectation = self.expectation(description: "saw packets")
    var channels = Set<Int>()
    let token = monitor.addMonitor { data in
      channels.insert(data.channel)
      if channels.count == 2 {
        expectation.fulfill()
      }
    }

    let uniqueId: MIDIUniqueID = 123
    list.parse(receiver: nil, monitor: monitor, uniqueId: uniqueId)

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(channels, Set<Int>([1, 2]))
  }
}
