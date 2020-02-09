// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import SoundFontsFramework

/**
 Plays notes from keyboard using Sampler and shows the note values being played on InfoBar.
 */
final class NotePlayer: KeyboardDelegate {

    private let infoBar: InfoBar
    private let sampler: Sampler

    var isMuted: Bool = false

    init(infoBar: InfoBar, sampler: Sampler) {
        self.infoBar = infoBar
        self.sampler = sampler
    }

    /**
     Play a note with the sampler. Show note info in the info bar.

     - parameter note: the note to play
     */
    func noteOn(_ note: Note) {
        if isMuted {
            infoBar.setStatus("🔇")
        }
        else {
            infoBar.setStatus(note.label + " - " + note.solfege)
            sampler.noteOn(note.midiNoteValue)
        }
    }

    /**
     Stop playing a note with the sampler.

     - parameter note: the note to stop.
     */
    func noteOff(_ note: Note) {
        sampler.noteOff(note.midiNoteValue)
    }
}
