// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/// A unique combination of a SoundFont and one if its presets. This is the normal way to communicate what preset is
/// active and what a `favorite` item points to.
public struct SoundFontAndPreset: Codable, Hashable {
  public let soundFontKey: SoundFont.Key
  public let patchIndex: Int

  public init(soundFontKey: SoundFont.Key, presetIndex: Int) {
    self.soundFontKey = soundFontKey
    self.patchIndex = presetIndex
  }
}