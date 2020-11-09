// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Custom sequence / iterator that will spit out 2-tuples of CGRect and Note values for the next key in a keyboard view.
 */
internal struct KeyParamsSequence: Sequence, IteratorProtocol {
    private var nextMidiNote: Int
    private var lastMidiNote: Int
    private var nextX: CGFloat
    private let keyWidth: CGFloat
    private let keyHeight: CGFloat
    private let blackKeyHeightScale: CGFloat = 0.6
    private let blackKeyWidthScale: CGFloat = 13.0 / 16.0

    init(keyWidth: CGFloat, keyHeight: CGFloat, firstMidiNote: Int, lastMidiNote: Int) {
        self.nextMidiNote = firstMidiNote
        self.lastMidiNote = lastMidiNote
        self.nextX = 0.0
        self.keyWidth = keyWidth
        self.keyHeight = keyHeight
    }

    func makeIterator() -> KeyParamsSequence { self }

    mutating func next() -> (CGRect, Note)? {
        guard nextMidiNote <= lastMidiNote else { return nil }
        let note = Note(midiNoteValue: nextMidiNote)
        nextMidiNote += 1
        let advance = note.accented ? 0 : keyWidth
        let xWidth = note.accented ? keyWidth * blackKeyWidthScale : keyWidth
        let xPos = note.accented ? nextX - xWidth / 2 : nextX
        nextX += advance
        return (CGRect(x: xPos, y: 0, width: xWidth, height: (note.accented ? blackKeyHeightScale : 1.0) * keyHeight), note)
    }
}
