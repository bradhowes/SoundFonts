// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 A custom setting with a SoundFont patch and a keyboard configuration.
 */
struct Favorite: Codable {

    typealias Key = UUID

    let key: Key

    /// The patch to load
    let soundFontPatch: SoundFontPatch

    /// The name of the favorite configuration
    var name: String

    /// The starting note of the keyboard
    var keyboardLowestNote: Note

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
    init(soundFontPatch: SoundFontPatch, keyboardLowestNote: Note) {
        self.key = Key()
        self.name = soundFontPatch.patch.name
        self.keyboardLowestNote = keyboardLowestNote
        self.soundFontPatch = soundFontPatch
        self.keyboardLowestNote = keyboardLowestNote
        self.gain = 0.0
        self.pan = 0.0
    }
}

extension Favorite: Equatable {
    static func == (lhs: Favorite, rhs: Favorite) -> Bool { lhs.key == rhs.key }
}

extension Favorite: CustomStringConvertible {
    var description: String { "['\(name)' - \(soundFontPatch)]" }
}
