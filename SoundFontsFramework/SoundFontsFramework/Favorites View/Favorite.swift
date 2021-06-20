// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/// A custom setting with a SoundFont preset and a keyboard configuration.
public class Favorite: Codable {

  /// The type for the unique Key for a favorite
  public typealias Key = UUID

  /// Legacy encoding keys before consolidation into PresetConfig
  /// NOTE: do not change any key names
  enum V1Keys: String, CodingKey {
    case key
    case soundFontAndPatch
    case name
    case keyboardLowestNote
    case gain
    case pan
  }

  /// Encoding keys with PresetConfig
  /// NOTE: do not change any key names without setting a custom coding key
  enum V2Keys: String, CodingKey {
    case key
    case soundFontAndPreset = "soundFontAndPatch" // legacy naming
    case presetConfig
  }

  /// The unique key of the favorite
  public let key: Key
  /// The key for the preset
  public let soundFontAndPreset: SoundFontAndPreset
  /// The custom configuration for the preset
  public var presetConfig: PresetConfig {
    didSet { PresetConfig.changedNotification.post(value: presetConfig) }
  }

  /**
   Create a new instance. The name of the favorite will start with the name of the preset.

   - parameter soundFontAndPreset: the preset to use
   - parameter keyboardLowestNote: the starting note of the keyboard
   */
  public init(soundFontAndPreset: SoundFontAndPreset, presetConfig: PresetConfig, keyboardLowestNote: Note?) {
    self.key = Key()
    self.soundFontAndPreset = soundFontAndPreset
    self.presetConfig = presetConfig
    self.presetConfig.keyboardLowestNote = keyboardLowestNote
    self.presetConfig.keyboardLowestNoteEnabled = false
  }

  /**
   Instantiate a Favorite using saved encoding.

   - parameter decoder: the container to decode from
   - throws exception if unable to decode
   */
  public required init(from decoder: Decoder) throws {
    do {
      // Attempt to decode the latest version first
      let values = try decoder.container(keyedBy: V2Keys.self)
      let key = try values.decode(Key.self, forKey: .key)
      let soundFontAndPreset = try values.decode(SoundFontAndPreset.self, forKey: .soundFontAndPreset)
      let presetConfig = try values.decode(PresetConfig.self, forKey: .presetConfig)
      self.key = key
      self.soundFontAndPreset = soundFontAndPreset
      self.presetConfig = presetConfig
    } catch {
      let err = error
      do {
        // Attempt to decode previous version, building a PresetConfig from the values at hand
        let values = try decoder.container(keyedBy: V1Keys.self)
        let key = try values.decode(Key.self, forKey: .key)
        let soundFontAndPreset = try values.decode(SoundFontAndPreset.self, forKey: .soundFontAndPatch)
        let name = try values.decode(String.self, forKey: .name)
        let lowestNote = try values.decodeIfPresent(Note.self, forKey: .keyboardLowestNote)
        let gain = try values.decode(Float.self, forKey: .gain)
        let pan = try values.decode(Float.self, forKey: .pan)
        self.key = key
        self.soundFontAndPreset = soundFontAndPreset
        self.presetConfig = PresetConfig(
          name: name, keyboardLowestNote: lowestNote,
          keyboardLowestNoteEnabled: lowestNote != nil,
          gain: gain, pan: pan,
          presetTuning: 0.0, presetTuningEnabled: false)
      } catch {
        throw err
      }
    }
  }

  /**
   Custom encoder for the class because of the custom decoding.

   - parameter encoder: the container to encode into
   - throws exception if unable to encode
   */
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: V2Keys.self)
    try container.encode(key, forKey: .key)
    try container.encode(soundFontAndPreset, forKey: .soundFontAndPreset)
    try container.encode(presetConfig, forKey: .presetConfig)
  }
}

extension Favorite: Equatable {
  /**
   Support equality operator

   - parameter lhs: first argument to compare
   - parameter rhs: second argument to compare
   - returns: true if same
   */
  public static func == (lhs: Favorite, rhs: Favorite) -> Bool { lhs.key == rhs.key }
}

extension Favorite: CustomStringConvertible {
  /// Custom string representation for a favorite
  public var description: String { "['\(presetConfig.name)' - \(soundFontAndPreset)]" }
}
