// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// A unique combination of a SoundFont and one if its presets. This is the normal way to communicate what preset is
/// active and what a `favorite` item points to.
public struct SoundFontAndPreset: Codable, Hashable {

  enum CodingKeys: String, CodingKey {
    case soundFontKey
    case presetIndex = "patchIndex" // legacy name
    case name
  }

  public let soundFontKey: SoundFont.Key
  public let presetIndex: Int
  public let name: String

  public init(soundFontKey: SoundFont.Key, presetIndex: Int, name: String) {
    self.soundFontKey = soundFontKey
    self.presetIndex = presetIndex
    self.name = name
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    self.soundFontKey = try values.decode(UUID.self, forKey: .soundFontKey)
    self.presetIndex = try values.decode(Int.self, forKey: .presetIndex)
    self.name = (try? values.decode(String.self, forKey: .name)) ?? "???"
  }
}

extension SoundFontAndPreset: CustomStringConvertible {
  /// Custom string representation for a favorite
  public var description: String { "[\(soundFontKey) - \(presetIndex) '\(name)']" }
}
