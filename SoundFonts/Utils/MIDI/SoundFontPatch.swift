// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 A unique combination of a SoundFont and one if its patches. This is the normal way to communicate what patch is active
 and what a `favorite` item points to.
 */
struct SoundFontPatch: Codable, Hashable {
    let soundFont: SoundFont
    let patchIndex: Int
    var patch: Patch { soundFont.patches[patchIndex] }
}

extension SoundFontPatch: CustomStringConvertible {
    var description: String { "['\(soundFont.displayName)' - '\(patch.name)']" }
}
