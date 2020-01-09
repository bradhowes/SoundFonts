// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 A unique combination of a SoundFont and one if its patches. This is the normal way to communicate what patch is active
 and what a `favorite` item points to.
 */
public struct SoundFontPatch: Codable, Hashable {
    public let soundFont: SoundFont
    public let patchIndex: Int
    public var patch: Patch { soundFont.patches[patchIndex] }
}

extension SoundFontPatch: CustomStringConvertible {
    public var description: String { "['\(soundFont.displayName)' - '\(patch.name)']" }
}
