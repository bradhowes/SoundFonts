// Copyright © 2020 Brad Howes. All rights reserved.

@testable import SoundFontsFramework
import CoreMIDI
import XCTest

class MIDIEventPacketTesting: XCTestCase {

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
}
