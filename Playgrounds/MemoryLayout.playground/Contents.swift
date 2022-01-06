import Foundation
import CoreMIDI

MemoryLayout<Int>.size          // returns 8 (on 64-bit)
MemoryLayout<Int>.alignment     // returns 8 (on 64-bit)
MemoryLayout<Int>.stride        // returns 8 (on 64-bit)

MemoryLayout<Int16>.size        // returns 2
MemoryLayout<Int16>.alignment   // returns 2
MemoryLayout<Int16>.stride      // returns 2

MemoryLayout<Bool>.size         // returns 1
MemoryLayout<Bool>.alignment    // returns 1
MemoryLayout<Bool>.stride       // returns 1

MemoryLayout<Float>.size        // returns 4
MemoryLayout<Float>.alignment   // returns 4
MemoryLayout<Float>.stride      // returns 4

MemoryLayout<Double>.size       // returns 8
MemoryLayout<Double>.alignment  // returns 8
MemoryLayout<Double>.stride     // returns 8

struct EmptyStruct {}

MemoryLayout<EmptyStruct>.size      // returns 0
MemoryLayout<EmptyStruct>.alignment // returns 1
MemoryLayout<EmptyStruct>.stride    // returns 1

struct SampleStruct {
  let number: UInt32
  let flag: Bool
}

MemoryLayout<SampleStruct>.size       // returns 5
MemoryLayout<SampleStruct>.alignment  // returns 4
MemoryLayout<SampleStruct>.stride     // returns 8

class EmptyClass {}

MemoryLayout<EmptyClass>.size      // returns 8 (on 64-bit)
MemoryLayout<EmptyClass>.stride    // returns 8 (on 64-bit)
MemoryLayout<EmptyClass>.alignment // returns 8 (on 64-bit)

class SampleClass {
  let number: Int64 = 0
  let flag = false
}

MemoryLayout<SampleClass>.size      // returns 8 (on 64-bit)
MemoryLayout<SampleClass>.stride    // returns 8 (on 64-bit)
MemoryLayout<SampleClass>.alignment // returns 8 (on 64-bit)

func makePacket(timeStamp: MIDITimeStamp, bytes: [UInt8]) -> MIDIPacket {
  var packet = MIDIPacket()
  packet.timeStamp = timeStamp
  packet.length = UInt16(bytes.count)
  withUnsafeMutableBytes(of: &packet.data) { $0.copyBytes(from: bytes) }
  return packet
}

do {
  let packet1 = makePacket(timeStamp: 123, bytes: [1, 2, 3])
  packet1.length
  packet1.data.0
  packet1.data.1
  packet1.data.2

  let packet2 = makePacket(timeStamp: 124, bytes: [4, 5])
  packet2.length
  packet2.data.0
  packet2.data.1

  let maxPacketListSize = 65536
  var packetListData = Data(count: maxPacketListSize)

  let packetList = packetListData.withUnsafeMutableBytes { (packetListRawBufferPtr: UnsafeMutableRawBufferPointer) -> MIDIPacketList in
    let packetListPtr = packetListRawBufferPtr.bindMemory(to: MIDIPacketList.self).baseAddress!

    var curPacketPtr = MIDIPacketListInit(packetListPtr)
    curPacketPtr = withUnsafePointer(to: packet1.data.0) { ptr in
      MIDIPacketListAdd(packetListPtr, maxPacketListSize, curPacketPtr, packet1.timeStamp, Int(packet1.length), ptr)
    }

    curPacketPtr = withUnsafePointer(to: packet2.data.0) { ptr in
      MIDIPacketListAdd(packetListPtr, maxPacketListSize, curPacketPtr, packet2.timeStamp, Int(packet2.length), ptr)
    }

    return packetListPtr.move()
  }

  packetList.numPackets
}

// 1
let count = 2
let stride = MemoryLayout<Int>.stride
let alignment = MemoryLayout<Int>.alignment
let byteCount = stride * count

// 2
do {
  print("Raw pointers")

  // 3
  let pointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
  // 4
  defer {
    pointer.deallocate()
  }

  // 5
  pointer.storeBytes(of: 42, as: Int.self)
  pointer.advanced(by: stride).storeBytes(of: 6, as: Int.self)
  pointer.load(as: Int.self)
  pointer.advanced(by: stride).load(as: Int.self)

  // 6
  let bufferPointer = UnsafeRawBufferPointer(start: pointer, count: byteCount)
  for (index, byte) in bufferPointer.enumerated() {
    print("byte \(index): \(byte)")
  }
}

do {
  print("Typed pointers")

  let pointer = UnsafeMutablePointer<Int>.allocate(capacity: count)
  pointer.initialize(repeating: 0, count: count)
  defer {
    pointer.deinitialize(count: count)
    pointer.deallocate()
  }

  pointer.pointee = 42
  pointer.advanced(by: 1).pointee = 6
  pointer.pointee
  pointer.advanced(by: 1).pointee

  let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
  for (index, value) in bufferPointer.enumerated() {
    print("value \(index): \(value)")
  }
}

do {
  print("Converting raw pointers to typed pointers")

  let rawPointer = UnsafeMutableRawPointer.allocate(
    byteCount: byteCount,
    alignment: alignment)
  defer {
    rawPointer.deallocate()
  }

  let typedPointer = rawPointer.bindMemory(to: Int.self, capacity: count)
  typedPointer.initialize(repeating: 0, count: count)
  defer {
    typedPointer.deinitialize(count: count)
  }

  typedPointer.pointee = 42
  typedPointer.advanced(by: 1).pointee = 6
  typedPointer.pointee
  typedPointer.advanced(by: 1).pointee

  let bufferPointer = UnsafeBufferPointer(start: typedPointer, count: count)
  for (index, value) in bufferPointer.enumerated() {
    print("value \(index): \(value)")
  }
}
