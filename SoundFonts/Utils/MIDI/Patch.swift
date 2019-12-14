// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox

/**
 Representation of a patch in a sound font.
 */
struct Patch: Codable {

    /// Display name for the patch
    let name: String

    /// Width of the name in the system font
    // lazy var nameWidth: CGFloat = name.systemFontWidth

    /// Bank number where the patch resides in the sound font
    let bank: Int

    /// Program patch number where the patch resides in the sound font
    let patch: Int

    /// The index into the owning soundFont's patches array
    var soundFontIndex: Int

    /**
     There are two types of MIDI banks in the General MIDI standard: melody and percussion
     */
    enum MidiBankType {
        static let kBankSize = 256

        case percussion
        case melody
        case custom(bank: Int)

        static func basedOn(bank: Int) -> MidiBankType {
            if bank == 128 {
                return .percussion
            }
            else if bank == 0 {
                return .melody
            }
            else {
                return .custom(bank: bank)
            }
        }

        /// Obtain the most-significant byte of the bank for the program/voice
        var bankMSB: Int {
            switch self {
            case .percussion: return kAUSampler_DefaultPercussionBankMSB
            case .melody:     return kAUSampler_DefaultMelodicBankMSB
            case .custom:     return kAUSampler_DefaultMelodicBankMSB
            }
        }

        /// Obtain the least-significant byte of the bank for the program/voice
        var bankLSB: Int {
            switch self {
            case .percussion:       return kAUSampler_DefaultBankLSB
            case .melody:           return kAUSampler_DefaultBankLSB
            case .custom(let bank): return bank
            }
        }
    }

    private var midiBankType: MidiBankType { MidiBankType.basedOn(bank: bank) }

    /// Obtain the most-significant byte for the bank
    var bankMSB: Int { midiBankType.bankMSB }

    /// Obtain the least-significant byte for the bank
    var bankLSB: Int { midiBankType.bankLSB }

    /**
     Initialize Patch instance.

     - parameter name: the diplay name for the patch
     - parameter bank: the bank where the patch resides
     - parameter patch: the program ID of the patch in the sound font
     */
    init(_ name: String, _ bank: Int, _ patch: Int, _ index: Int) {
        self.name = name
        self.bank = bank
        self.patch = patch
        self.soundFontIndex = index
    }
}

//extension Patch: Hashable {
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(key)
//    }
//
//    static func == (lhs: Patch, rhs: Patch) -> Bool {
//        lhs.index == rhs.index
//    }
//}

extension Patch: CustomStringConvertible {
    var description: String { "[Patch '\(name)' \(bank):\(patch)]" }
}
