// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import os

/**
 Representation of a patch in a sound font.
 */
final public class LegacyPatch: Codable {
    static let log = Logging.logger("LegacyPatch")

    private enum V1Keys: String, CodingKey {
        case name
        case bank
        case program
        case soundFontIndex
        case isVisible
        case reverbConfig
        case delayConfig
    }

    private enum V2Keys: String, CodingKey {
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

    /// Configuration parameters that can be adjusted by the user.
    public var presetConfig: PresetConfig { didSet { PresetConfig.changedNotification.post(value: presetConfig) } }

    public var favorites: [LegacyFavorite.Key] = []

    private var bankType: MIDIBankType { MIDIBankType.basedOn(bank: bank) }

    /// Obtain the most-significant byte for the bank
    public var bankMSB: Int { bankType.bankMSB }

    /// Obtain the least-significant byte for the bank
    public var bankLSB: Int { bankType.bankLSB }

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
        self.presetConfig = PresetConfig(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: V2Keys.self)
            let originalName = try values.decode(String.self, forKey: .originalName)
            let bank = try values.decode(Int.self, forKey: .bank)
            let program = try values.decode(Int.self, forKey: .program)
            let soundFontIndex = try values.decode(Int.self, forKey: .soundFontIndex)
            let presetConfig = try values.decode(PresetConfig.self, forKey: .presetConfig)
            let favorites = try values.decodeIfPresent(Array<LegacyFavorite.Key>.self, forKey: .favorites) ?? []
            self.originalName = originalName
            self.bank = bank
            self.program = program
            self.soundFontIndex = soundFontIndex
            self.presetConfig = presetConfig
            self.favorites = favorites
        }
        catch {
            let err = error
            os_log(.error, log: Self.log, "failed to decode V2 - %{public}s", error.localizedDescription)
            do {
                let values = try decoder.container(keyedBy: V1Keys.self)
                let name = try values.decode(String.self, forKey: .name)
                let bank = try values.decode(Int.self, forKey: .bank)
                let program = try values.decode(Int.self, forKey: .program)
                let soundFontIndex = try values.decode(Int.self, forKey: .soundFontIndex)
                let reverbConfig = try values.decodeIfPresent(ReverbConfig.self, forKey: .reverbConfig)
                let delayConfig = try values.decodeIfPresent(DelayConfig.self, forKey: .delayConfig)

                self.originalName = name
                self.bank = bank
                self.program = program
                self.soundFontIndex = soundFontIndex
                self.presetConfig = PresetConfig(name: name, keyboardLowestNote: nil, keyboardLowestNoteEnabled: false,
                                                 reverbConfig: reverbConfig, delayConfig: delayConfig,
                                                 gain: 0.0, pan: 0.0, presetTuning: 0.0, presetTuningEnabled: false)
            } catch {
                throw err
            }
        }
    }
}

extension LegacyPatch {
    func makeFavorite(soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote: Note?) -> LegacyFavorite {
        os_log(.info, log: Self.log, "makeFavorite")
        var newConfig = presetConfig
        newConfig.name = presetConfig.name + " \(favorites.count + 1)"
        os_log(.info, log: Self.log, "makeFavorite - '%{public}s'", newConfig.name)
        let favorite = LegacyFavorite(soundFontAndPatch: soundFontAndPatch, presetConfig: newConfig,
                                      keyboardLowestNote: keyboardLowestNote)
        favorites.append(favorite.key)
        return favorite
    }
}

extension LegacyPatch: CustomStringConvertible {
    public var description: String { "[Patch '\(originalName)' \(bank):\(program)]" }
}
