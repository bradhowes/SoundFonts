// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit
import AudioToolbox

/**
 Representation of a patch in a sound font.
 */
public struct Patch: Codable {

    /// Display name for the patch
    public let name: String
    /// Width of the name in the system font
    public lazy var nameWidth: CGFloat = name.systemFontWidth
    /// Bank number where the patch resides in the sound font
    public let bank: Int
    /// Program patch number where the patch resides in the sound font
    public let patch: Int
    /// The index of the Patch in the SoundFont array of patches
    public let index: Int

    private let soundFontName: String

    public var soundFont: SoundFont? { SoundFontLibrary.shared.getByName(soundFontName) }

    /**
     There are two types of MIDI banks in the General MIDI standard: melody and percussion
     */
    public enum MidiBankType {
        static public let kBankSize = 256

        case percussion
        case melody
        case custom(bank: Int)

        public static func basedOn(bank: Int) -> MidiBankType {
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
        public var bankMSB: Int {
            switch self {
            case .percussion: return kAUSampler_DefaultPercussionBankMSB
            case .melody:     return kAUSampler_DefaultMelodicBankMSB
            case .custom:     return kAUSampler_DefaultMelodicBankMSB
            }
        }

        /// Obtain the least-significant byte of the bank for the program/voice
        public var bankLSB: Int {
            switch self {
            case .percussion:       return kAUSampler_DefaultBankLSB
            case .melody:           return kAUSampler_DefaultBankLSB
            case .custom(let bank): return bank
            }
        }
    }

    /// Obtain the MIDI bank type for this InstrumentVoice
    private var midiBankType: MidiBankType { MidiBankType.basedOn(bank: bank) }

    public var bankMSB: Int { midiBankType.bankMSB }
    public var bankLSB: Int { midiBankType.bankLSB }

    /**
     Initialize Patch instance.

     - parameter name: the diplay name for the patch
     - parameter bank: the bank where the patch resides
     - parameter patch: the program ID of the patch in the sound font
     */
    init(_ name: String, _ bank: Int, _ patch: Int, _ index: Int, _ soundFontName: String) {
        self.name = name
        self.bank = bank
        self.patch = patch
        self.index = index
        self.soundFontName = soundFontName
    }
}

extension Patch: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bank)
        hasher.combine(patch)
        hasher.combine(soundFont)
    }

    public static func == (lhs: Patch, rhs: Patch) -> Bool {
        lhs.bank == rhs.bank && lhs.patch == rhs.patch && lhs.soundFontName == rhs.soundFontName
    }
}

extension Patch: CustomStringConvertible {
    public var description: String { "[Patch '\(name)' \(bank):\(patch) (\(soundFontName))]" }
}
