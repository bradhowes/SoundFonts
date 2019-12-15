// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

struct SoundFontPatch: Codable, Hashable {
    let soundFont: SoundFont
    let patchIndex: Int
    var patch: Patch { soundFont.patches[patchIndex] }
}

extension SoundFontPatch: CustomStringConvertible {
    var description: String { "['\(soundFont.displayName)' - '\(patch.name)']" }
}
