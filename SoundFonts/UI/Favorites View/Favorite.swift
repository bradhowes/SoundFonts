//
//  Favorite.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/23/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation

fileprivate extension String {
    static let name = "name"
    static let patch = "patch"
    static let lowestNote = "lowestNote"
    static let gain = "gain"
    static let pan = "pan"
}

/**
 A custom setting with a SoundFont patch and a keyboard configuration.
 */
final class Favorite: NSObject, NSCoding {
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
        super.init()
    }

    /**
     Restore an instance from values in an NSCoder decoder
    
     - parameter aDecoder: the decoder containing the values to use
     */
    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: .name) as? String,
            let patch = aDecoder.decodeObject(forKey: .patch) as? Patch else { return nil }
        self.name = name
        self.patch = patch
        
        // NOTE: these are not entirely safe since they will return default 0 or 0.0 values if the key does not
        // exist. However, these default values are also the defaults for a new Favorite instance, so we don't mind.
        self.keyboardLowestNote = Note(midiNoteValue: aDecoder.decodeInteger(forKey: .lowestNote))
        self.gain = aDecoder.decodeFloat(forKey: .gain)
        self.pan = aDecoder.decodeFloat(forKey: .pan)
        super.init()
    }

    /**
     Encode the Favorite instance.
    
     - parameter aCoder: the encoder to hold the encoding
     */
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: .name)
        aCoder.encode(patch, forKey: .patch)
        aCoder.encode(keyboardLowestNote.midiNoteValue, forKey: .lowestNote)
        aCoder.encode(gain, forKey: .gain)
        aCoder.encode(pan, forKey: .pan)
    }
}
