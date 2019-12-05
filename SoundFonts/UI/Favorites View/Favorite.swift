// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 A custom setting with a SoundFont patch and a keyboard configuration.
 */
final class Favorite: Codable {

    /// The name of the favorite configuration
    var name: String

    /// The starting note of the keyboard
    var keyboardLowestNote: Note

    /// The patch to load
    let patch: Patch

    /// Gain applied to sampler output. Valid values [-90..+12] with default 0.0 See doc for `AVAudioUnitSampler`
    var gain: Float

    /// Stereo panning applied to sampler output. Valid values [-1..+1] with default 0.0. See doc for
    /// `AVAudioUnitSampler`
    var pan: Float

    /**
     Create a new instance. The name of the favorite will start with the name of the patch.
    
     - parameter patch: the Patch to use
     - parameter keyboardLowestNote: the starting note of the keyboard
     */
    init(patch: Patch, keyboardLowestNote: Note) {
        self.name = patch.name
        self.keyboardLowestNote = keyboardLowestNote
        self.patch = patch
        self.gain = 0.0
        self.pan = 0.0
    }
}

extension Favorite: Equatable {
    static func == (lhs: Favorite, rhs: Favorite) -> Bool { lhs.patch == rhs.patch }
}

extension Favorite: CustomStringConvertible {
    var description: String { "[Favorite '\(name)' \(patch)]" }
}
