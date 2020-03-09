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

    /**
     Initialize new instance.

     - parameter infoBar: InfoBar instance to use to display note values
     - parameter sampler: the Sampler instance to use to play notes
     */
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
            if Settings[.showSolfegeLabel] {
                infoBar.setStatus(note.label + " - " + note.solfege)
            }
            else {
                infoBar.setStatus(note.label)
            }
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
