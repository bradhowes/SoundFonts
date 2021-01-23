// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox

/**
 Representation of a patch in a sound font.
 */
final public class LegacyPatch: Codable {

    enum V1Keys: String, CodingKey {
        case name
        case bank
        case program
        case soundFontIndex
        case isVisible
        case reverbConfig
        case delayConfig
        case presetConfig
    }

    /// Original name for the preset/patch
    public let originalName: String

    /// Bank number where the patch resides in the sound font
    public let bank: Int

    /// Program patch number where the patch resides in the sound font
    public let program: Int

    /// The index into the owning soundFont's patches array
    public let soundFontIndex: Int

    /// Determines the visibility of a preset in a UI view.
    var isVisible: Bool

    /// The reverb configuration attached to the preset (NOTE: not applicable in AUv3 extension)
    var reverbConfig: ReverbConfig?

    /// The delay configuration attached to the preset (NOTE: not applicable in AUv3 extension)
    var delayConfig: DelayConfig?

    /// Configuration parameters that can be adjusted by the user.
    var presetConfig: PresetConfig {
        didSet {
            PresetConfig.changedNotification.post(value: presetConfig)
        }
    }

    /**
     There are two types of MIDI banks in the General MIDI standard: melody and percussion
     */
    private enum MidiBankType {
        static let kBankSize = 256

        case percussion
        case melody
        case custom(bank: Int)

        static func basedOn(bank: Int) -> MidiBankType {
            switch bank {
            case 0:   return .melody
            case 128: return .percussion
            default:  return .custom(bank: bank)
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
    public var bankMSB: Int { midiBankType.bankMSB }

    /// Obtain the least-significant byte for the bank
    public var bankLSB: Int { midiBankType.bankLSB }

    /**
     Initialize Patch instance.

     - parameter name: the display name for the patch
     - parameter bank: the bank where the patch resides
     - parameter patch: the program ID of the patch in the sound font
     */
    public init(_ name: String, _ bank: Int, _ program: Int, _ index: Int) {
        self.originalName = name
        self.bank = bank
        self.program = program
        self.soundFontIndex = index
        self.isVisible = true
        self.presetConfig = PresetConfig(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: V1Keys.self)
        let name = try values.decode(String.self, forKey: .name)
        self.originalName = name
        self.bank = try values.decode(Int.self, forKey: .bank)
        self.program = try values.decode(Int.self, forKey: .program)
        self.soundFontIndex = try values.decode(Int.self, forKey: .soundFontIndex)
        self.isVisible = try values.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        self.reverbConfig = try values.decodeIfPresent(ReverbConfig.self, forKey: .reverbConfig)
        self.delayConfig = try values.decodeIfPresent(DelayConfig.self, forKey: .delayConfig)
        self.presetConfig = try values.decodeIfPresent(PresetConfig.self, forKey: .presetConfig) ??
            PresetConfig(name: name)
    }
}

extension LegacyPatch: CustomStringConvertible {
    public var description: String { "[Patch '\(originalName)' \(bank):\(program)]" }
}
