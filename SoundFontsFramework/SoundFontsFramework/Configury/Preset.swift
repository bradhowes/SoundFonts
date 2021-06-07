// Copyright © 2019 Brad Howes. All rights reserved.

import AudioToolbox
import Foundation
import os

/// Representation of a patch in a sound font.
final public class Preset: Codable {
  private static let log = Logging.logger("Preset")
  private var log: OSLog { Self.log }

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

  /// The index into the owning soundFont's presets array
  public let soundFontIndex: Int

  /// Configuration parameters that can be adjusted by the user.
  public var presetConfig: PresetConfig {
    didSet { PresetConfig.changedNotification.post(value: presetConfig) }
  }

  public var favorites: [Favorite.Key] = []

  private var bankType: MIDIBankType { MIDIBankType.basedOn(bank: bank) }

  /// Obtain the most-significant byte for the bank
  public var bankMSB: Int { bankType.bankMSB }

  /// Obtain the least-significant byte for the bank
  public var bankLSB: Int { bankType.bankLSB }

  /**
   Initialize instance.

   - parameter name: the display name for the patch
   - parameter bank: the bank where the patch resides
   - parameter program: the program ID of the patch in the sound font
   - parameter index: the entry for the preset in the sound font presets array
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
      let favorites = try values.decodeIfPresent(Array<Favorite.Key>.self, forKey: .favorites) ?? []

      self.originalName = originalName
      self.bank = bank
      self.program = program
      self.soundFontIndex = soundFontIndex
      self.presetConfig = presetConfig
      self.favorites = favorites
    } catch {
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
                                         reverbConfig: reverbConfig, delayConfig: delayConfig, gain: 0.0, pan: 0.0,
                                         presetTuning: 0.0, presetTuningEnabled: false)
      } catch {
        throw err
      }
    }
  }
}

extension Preset {
  func makeFavorite(soundFontAndPreset: SoundFontAndPreset, keyboardLowestNote: Note?) -> Favorite {
    os_log(.info, log: log, "makeFavorite")
    var newConfig = presetConfig
    newConfig.name = presetConfig.name
    os_log(.info, log: log, "makeFavorite - '%{public}s'", newConfig.name)
    let favorite = Favorite(soundFontAndPreset: soundFontAndPreset, presetConfig: newConfig,
                            keyboardLowestNote: keyboardLowestNote)
    favorites.append(favorite.key)
    return favorite
  }

  func validate(_ favorites: Favorites) {
    var invalidFavoriteIndices = [Int]()
    for (favoriteIndex, favoriteKey) in self.favorites.enumerated().reversed() {
      if !favorites.contains(key: favoriteKey) {
        os_log(.error, log: log, "preset '%{public}s' has invalid favorite key '%{public}s'", self.presetConfig.name,
               favoriteKey.uuidString)
        invalidFavoriteIndices.append(favoriteIndex)
      }
    }

    for index in invalidFavoriteIndices {
      self.favorites.remove(at: index)
    }
  }
}

extension Preset: CustomStringConvertible {
  public var description: String { "[Preset '\(originalName)' \(bank):\(program)]" }
}
