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
    }

    enum V2Keys: String, CodingKey {
        case originalName
        case bank
        case program
        case soundFontIndex
        case isVisible
        case presetConfig
        case favorites
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

    /// Configuration parameters that can be adjusted by the user.
    var presetConfig: PresetConfig {
        didSet {
            PresetConfig.changedNotification.post(value: presetConfig)
        }
    }

    var favorites: [LegacyFavorite.Key] = []

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
        do {
            let values = try decoder.container(keyedBy: V2Keys.self)
            let originalName = try values.decode(String.self, forKey: .originalName)
            let bank = try values.decode(Int.self, forKey: .bank)
            let program = try values.decode(Int.self, forKey: .program)
            let soundFontIndex = try values.decode(Int.self, forKey: .soundFontIndex)
            let isVisible = try values.decode(Bool.self, forKey: .isVisible)
            let presetConfig = try values.decode(PresetConfig.self, forKey: .presetConfig)
            let favorites = try values.decodeIfPresent(Array<LegacyFavorite.Key>.self, forKey: .favorites) ?? []

            self.originalName = originalName
            self.bank = bank
            self.program = program
            self.soundFontIndex = soundFontIndex
            self.isVisible = isVisible
            self.presetConfig = presetConfig
            self.favorites = favorites
        }
        catch {
            let err = error
            do {
                let values = try decoder.container(keyedBy: V1Keys.self)
                let name = try values.decode(String.self, forKey: .name)
                let bank = try values.decode(Int.self, forKey: .bank)
                let program = try values.decode(Int.self, forKey: .program)
                let soundFontIndex = try values.decode(Int.self, forKey: .soundFontIndex)
                let isVisible = try values.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
                let reverbConfig = try values.decodeIfPresent(ReverbConfig.self, forKey: .reverbConfig)
                let delayConfig = try values.decodeIfPresent(DelayConfig.self, forKey: .delayConfig)

                self.originalName = name
                self.bank = bank
                self.program = program
                self.soundFontIndex = soundFontIndex
                self.isVisible = isVisible
                self.presetConfig = PresetConfig(name: name, keyboardLowestNote: nil, keyboardLowestNoteEnabled: false,
                                                 reverbConfig: reverbConfig, delayConfig: delayConfig,
                                                 gain: 0.0, pan: 0.0, presetTuning: 0.0, presetTuningEnabled: false)
            } catch {
                throw err
            }
        }
    }

    func makeFavorite(soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote: Note?) -> LegacyFavorite {
        var newConfig = presetConfig
        newConfig.name = presetConfig.name + " \(favorites.count + 1)"
        let favorite = LegacyFavorite(soundFontAndPatch: soundFontAndPatch, presetConfig: newConfig,
                                      keyboardLowestNote: keyboardLowestNote)
        favorites.append(favorite.key)
        return favorite
    }
}

extension LegacyPatch: CustomStringConvertible {
    public var description: String { "[Patch '\(originalName)' \(bank):\(program)]" }
}
