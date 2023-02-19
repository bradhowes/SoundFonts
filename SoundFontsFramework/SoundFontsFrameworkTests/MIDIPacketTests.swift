// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import CoreMIDI
import XCTest

class MIDIPacketTesting: XCTestCase {

  class Receiver: AnyMIDIReceiver {

    func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {}
    func setController(controller: UInt8, value: UInt8, channel: UInt8) {}
    func changeProgram(program: UInt8, channel: UInt8) {}
    func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {}
    func setPressure(pressure: UInt8, channel: UInt8) {}
    func setPitchBend(value: UInt16, channel: UInt8) {}
    func processMIDIEvent(status: UInt8, data1: UInt8) {}
    func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {}

    struct Event: Equatable {
      let cmd: MIDI1Msg
      let data1: UInt8
      let data2: UInt8
      let channel: UInt8
    }

    var channel: Int = -1
    var received = [Event]()

    func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {
      received.append(Event(cmd: .noteOn, data1: note, data2: velocity, channel: channel))
    }

    func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {
      received.append(Event(cmd: .noteOff, data1: note, data2: velocity, channel: channel)) }

    func stopAllNotes() {
      received.append(Event(cmd: .reset, data1: 0x00, data2: 0x00, channel: 0x00))
    }
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

  func testParseReset() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOn = MIDIPacket.Builder(timestamp: 0, msg: .reset).packet
    noteOn.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: .reset, data1: 0, data2:0, channel: 0)])
  }

  func testParseNoteOn() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32]).packet
    noteOn.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: .noteOn, data1: 64, data2:32, channel: 1)])
  }

  func testParseNoteOff() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x81, 62, 30]).packet
    noteOn.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: .noteOff, data1: 62, data2: 0, channel: 1)])
  }

  func testParseZeroVelocityNoteOnAsNoteOff() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 0]).packet
    noteOn.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: .noteOff, data1: 64, data2: 0, channel: 1)])
  }

  func testParseWithRunningStatus() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOnOff = MIDIPacket.Builder(timestamp: 0, data: [0x90, 0x3C, 0x7F, 0x3C, 0x00]).packet
    noteOnOff.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertEqual(receiver.received, [Receiver.Event(cmd: .noteOn, data1: 0x3C, data2: 0x7F, channel: 0),
                                       Receiver.Event(cmd: .noteOff, data1: 0x3C, data2: 0x00, channel: 0)])
  }

  func testParserSkipsUnknownMessage() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let bogus = MIDIPacket.Builder(timestamp: 0, data: [0xF4, 0x91, 64, 32]).packet
    bogus.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParserSkipsIncompleteMessage() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOn = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64]).packet
    noteOn.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertTrue(receiver.received.isEmpty)
  }

  func testParseMultipleMessages() {
    let midi = MIDI(settings: Settings(suiteName: "blah"))
    let receiver = Receiver()
    let noteOnOff = MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet
    noteOnOff.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 123)
    XCTAssertEqual(receiver.received, [
      Receiver.Event(cmd: .noteOn, data1: 64, data2: 32, channel: 1),
      Receiver.Event(cmd: .noteOff, data1: 64, data2: 0, channel: 1)
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
    let midi = MIDI(settings: Settings(suiteName: "blah"))

    var builder = MIDIPacketList.Builder()
    builder.add(packet: MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet)
    builder.add(packet: MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x81, 66, 0]).packet)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)
    list.parse(midi: midi, receiver: receiver, monitor: MIDIActivityNotifier(), endpoint: 0)

    XCTAssertEqual(receiver.received, [
      Receiver.Event(cmd: .noteOn, data1: 64, data2: 32, channel: 1),
      Receiver.Event(cmd: .noteOff, data1: 64, data2: 0, channel: 1),
      Receiver.Event(cmd: .noteOn, data1: 65, data2: 33, channel: 1),
      Receiver.Event(cmd: .noteOff, data1: 65, data2: 0, channel: 1),
      Receiver.Event(cmd: .noteOff, data1: 66, data2: 0, channel: 1)
    ])
  }

  func testMonitoringTraffic() {
    let monitor = MIDIActivityNotifier()
    let midi = MIDI(settings: Settings(suiteName: "blah"))

    var builder = MIDIPacketList.Builder()
    builder.add(packet: MIDIPacket.Builder(timestamp: 0, data: [0x91, 64, 32, 0x81, 64, 0]).packet)
    builder.add(packet: MIDIPacket.Builder(timestamp: 1, data: [0x91, 65, 33, 0x81, 65, 10, 0x82, 66, 0]).packet)

    let list = builder.packetList
    XCTAssertEqual(list.numPackets, 2)

    let expectation = self.expectation(description: "saw packets")
    var channels = Set<Int>()
    let skippy = monitor.addMonitor { data in
      channels.insert(data.channel)
      if channels.count == 2 {
        expectation.fulfill()
      }
    }

    XCTAssertNotNil(skippy)

    let endpoint: MIDIEndpointRef = 123
    list.parse(midi: midi, receiver: nil, monitor: monitor, endpoint: endpoint)

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(channels, Set<Int>([1, 2]))
  }
}
