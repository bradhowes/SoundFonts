import AVFoundation

/// There are two types of MIDI banks in the General MIDI standard: melody and percussion
enum MIDIBankType {
  static let kBankSize = 256

  case percussion
  case melody
  case custom(bank: Int)

  static func basedOn(bank: Int) -> MIDIBankType {
    switch bank {
    case 0: return .melody
    case 128: return .percussion
    default: return .custom(bank: bank)
    }
  }

  /// Obtain the most-significant byte of the bank for the program/voice
  var bankMSB: Int {
    switch self {
    case .percussion: return kAUSampler_DefaultPercussionBankMSB
    case .melody: return kAUSampler_DefaultMelodicBankMSB
    case .custom: return kAUSampler_DefaultMelodicBankMSB
    }
  }

  /// Obtain the least-significant byte of the bank for the program/voice
  var bankLSB: Int {
    switch self {
    case .percussion: return kAUSampler_DefaultBankLSB
    case .melody: return kAUSampler_DefaultBankLSB
    case .custom(let bank): return bank
    }
  }
}
