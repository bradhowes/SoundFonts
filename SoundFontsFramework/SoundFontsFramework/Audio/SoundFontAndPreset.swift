// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os.log

/// A unique combination of a SoundFont and one if its presets. This is the normal way to communicate what preset is
/// active and what a `favorite` item points to. This value is safe to store in a setting or configuration file since
/// the soundFontKey can be resolved during loading to make sure that the soundFont has not been removed.
public struct SoundFontAndPreset: Codable, Hashable {
  private static let log: Logger = Logging.logger("SoundFontAndPreset")
  private var log: Logger { Self.log }

  private enum V1Keys: String, CodingKey {
    case soundFontKey
    case presetIndex = "patchIndex" // legacy name
    case name
  }

  private enum V2Keys: String, CodingKey {
    case soundFontKey
    case soundFontName
    case presetIndex
    case itemName
  }

  /// The unique key associated with a SoundFont when it was added on a specific device
  public let soundFontKey: SoundFont.Key
  /// The name of the sound font. Used to resolve if the key is not found
  public let soundFontName: String
  /// The index of the preset in the SoundFont
  public let presetIndex: Int
  /// The display name of the preset or favorite. Only used for logging and debugging
  public let itemName: String

  public init(soundFontKey: SoundFont.Key, soundFontName: String, presetIndex: Int, itemName: String) {
    self.soundFontKey = soundFontKey
    self.soundFontName = soundFontName
    self.presetIndex = presetIndex
    self.itemName = itemName
  }

  public init(from decoder: Decoder) throws {
    do {
      let values = try decoder.container(keyedBy: V2Keys.self)
      let soundFontKey = try values.decode(UUID.self, forKey: .soundFontKey)
      let soundFontName = try values.decode(String.self, forKey: .soundFontName)
      let presetIndex = try values.decode(Int.self, forKey: .presetIndex)
      let itemName = try values.decode(String.self, forKey: .itemName)

      self.soundFontKey = soundFontKey
      self.soundFontName = soundFontName
      self.presetIndex = presetIndex
      self.itemName = itemName
    } catch {
      let err = error
      do {
        let values = try decoder.container(keyedBy: V1Keys.self)
        let soundFontKey = try values.decode(UUID.self, forKey: .soundFontKey)
        let presetIndex = try values.decode(Int.self, forKey: .presetIndex)
        let itemName = try? values.decode(String.self, forKey: .name)

        self.soundFontKey = soundFontKey
        self.soundFontName = "???"
        self.presetIndex = presetIndex
        self.itemName = itemName ?? "???"
      } catch {
        throw err
      }

      log.error("failed to decode V2 - \(error.localizedDescription, privacy: .public)")
    }
  }
}

extension SoundFontAndPreset: CustomStringConvertible {
  public var description: String { "<\(soundFontKey)[\(presetIndex)]: '\(itemName)'>" }
}
