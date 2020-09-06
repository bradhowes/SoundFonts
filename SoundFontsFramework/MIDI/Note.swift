// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 Definition of a MIDI note.
 */
public struct Note: CustomStringConvertible, Codable {

    static let sharpTag = "♯"
    static let noteLabels: [String] = ["C", "C", "D", "D", "E", "F", "F", "G", "G", "A", "A", "B"]
    static let solfegeLabels: [String] = ["Do", "Do", "Re", "Re", "Mi", "Fa", "Fa", "Sol", "Sol", "La", "La",
                                          "Ti"]

    /// The MIDI value to emit to generate this note
    public let midiNoteValue: Int

    /// True if this note is accented (sharp or flat)
    public let accented: Bool

    /// Obtain a textual representation of the note
    public var label: String {
        let noteIndex = midiNoteValue % 12
        let accent = accented ? Note.sharpTag : ""
        return "\(Note.noteLabels[noteIndex])\(accent)\(octave)"
    }

    /// Obtain the solfege representation for this note
    public var solfege: String { Note.solfegeLabels[midiNoteValue % 12] }

    /// Obtain the octave this note is a part of
    public var octave: Int { midiNoteValue / 12 - 1 }

    public var description: String { label }

    /**
     Create new Note instance.
    
     - parameter midiNoteValue: MIDI note value for this instance
     */
    public init(midiNoteValue: Int) {
        self.midiNoteValue = midiNoteValue
        let offset = midiNoteValue % 12
        self.accented = (offset < 5 && (offset & 1) == 1) || (offset > 5 && (offset & 1) == 0)
    }

    public init?(_ tag: String) {
        guard tag.count > 1 && tag.count < 5 else { return nil }
        let octave = tag.drop { !$0.isNumber }
        guard let octaveValue = Int(octave) else { return nil }
        var remaining = tag.dropLast(octave.count)
        guard let note = remaining.popFirst() else { return nil }
        let sharp = remaining.popFirst()
        guard let offset = Self.noteLabels.firstIndex(of: String(note)) else { return nil }
        self.midiNoteValue = (offset + (sharp != nil ? 1 : 0)) * octaveValue
        self.accented = sharp != nil
    }
}

extension Note: Equatable {
    public static func ==(lhs: Note, rhs: Note) -> Bool { lhs.midiNoteValue == rhs.midiNoteValue }
}

extension Note: Comparable {
    public static func <(lhs: Note, rhs: Note) -> Bool { lhs.midiNoteValue < rhs.midiNoteValue }
}
