// Copyright © 2023 Brad Howes. All rights reserved.

public enum MIDI1Msg: UInt8 {
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
    let nibbleHigh = raw.nibbleHigh
    self.init(rawValue: nibbleHigh == 0xF0 ? raw : nibbleHigh)
  }

  var hasChannel: Bool { self.rawValue < 0xF0 }

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
