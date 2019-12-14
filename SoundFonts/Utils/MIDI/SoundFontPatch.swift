// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

struct SoundFontPatch: CustomStringConvertible, Codable, Hashable {
    let soundFont: SoundFont
    let patchIndex: Int

    var description: String { "[SoundFontPatch '\(soundFont.displayName)' - '\(patchIndex)'" }
    var patch: Patch { soundFont.patches[patchIndex] }
}
