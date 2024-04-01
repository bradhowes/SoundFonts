// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/// Definition of a MIDI note.
public struct Note: CustomStringConvertible, Codable {

  static let sharpTag = "♯"
  static let flatTag = "♭"

  static let noteLabels: [String] = ["C",
                                     "C" + sharpTag,
                                     "D",
                                     "D" + sharpTag,
                                     "E",
                                     "F",
                                     "F" + sharpTag,
                                     "G",
                                     "G" + sharpTag,
                                     "A",
                                     "A" + sharpTag,
                                     "B"]
  static let solfegeLabels: [String] = ["Do", "Do", "Re", "Re", "Mi", "Fa", "Fa", "Sol", "Sol", "La", "La", "Ti"]
  static let sharpIndices: Set<Int> = [1, 3, 6, 8, 10]

  /// The MIDI value to emit to generate this note
  public let midiNoteValue: Int

  public let noteIndex: Int

  /// True if this note is accented (sharp or flat)
  var accented: Bool { Note.sharpIndices.contains(noteIndex) }

  /// Obtain a textual representation of the note
  var label: String { Note.noteLabels[noteIndex % 12] + "\(octave)" }

  /// Obtain the solfege representation for this note
  var solfege: String { Note.solfegeLabels[noteIndex] }

  /// Obtain the octave this note is a part of
  var octave: Int { midiNoteValue / 12 - 1 }

  /// Custom string representation for a Note instance
  public var description: String { label }

  /**
   Create new Note instance.

   - parameter midiNoteValue: MIDI note value for this instance
   */
  init(midiNoteValue: Int) {
    self.midiNoteValue = midiNoteValue
    let noteIndex = midiNoteValue % 12
    self.noteIndex = noteIndex
  }

  init?(_ tag: String) {
    guard tag.count > 1 && tag.count < 5 else { return nil }
    let octave = tag.drop { !$0.isNumber }
    guard let octaveValue = Int(octave) else { return nil }
    var remaining = tag.dropLast(octave.count)
    guard let note = remaining.popFirst() else { return nil }
    let sharp = remaining.popFirst()
    guard let offset = Self.noteLabels.firstIndex(of: String(note)) else { return nil }
    let midiNoteValue = (offset + (sharp != nil ? 1 : 0)) * octaveValue
    self.init(midiNoteValue: midiNoteValue)
  }
}

extension Note: Comparable {
  /**
   Allow for ordering of Note instances

   - parameter lhs: first argument to compare
   - parameter rhs: second argument to compare
   - returns: true if first comes before the second
   */
  public static func < (lhs: Note, rhs: Note) -> Bool { lhs.midiNoteValue < rhs.midiNoteValue }

  /**
   Allow for equality comparisons between Note instances

   - parameter lhs: first argument to compare
   - parameter rhs: second argument to compare
   - returns: true if the same
   */
  public static func == (lhs: Note, rhs: Note) -> Bool { lhs.midiNoteValue == rhs.midiNoteValue }
}
