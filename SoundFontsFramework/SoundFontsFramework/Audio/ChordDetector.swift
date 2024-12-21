// Copyright © 2024 Brad Howes. All rights reserved.

import Foundation

/// Definition of a MIDI note.
public struct ChordDetector {
  struct Chord {
    let intervals: [Int]
    let name: String
    let suffix: String
  }

  static let known: [Chord] = [
    .init(intervals: [4, 3, 5], name: "major", suffix: ""),
    .init(intervals: [3, 4, 5], name: "minor", suffix: "m"),
    .init(intervals: [4, 4, 4], name: "augmented", suffix: "aug"),
    .init(intervals: [3, 3, 6], name: "diminished", suffix: "dim"),
    .init(intervals: [2, 5, 5], name: "suspended", suffix: "sus2"),
    .init(intervals: [5, 2, 5], name: "suspended", suffix: "sus4"),
    .init(intervals: [7, 4, 1], name: "7major(short)", suffix: "7maj"),
    .init(intervals: [7, 3, 2], name: "7(short)", suffix: "7"),
    .init(intervals: [4, 3, 2, 3], name: "6major", suffix: "6maj"),
    .init(intervals: [3, 4, 2, 3], name: "6minor", suffix: "6min"),
    .init(intervals: [3, 3, 3, 3], name: "7dmininished", suffix: "7dim"),
    .init(intervals: [4, 3, 4, 1], name: "7major", suffix: "7maj"),
    .init(intervals: [3, 4, 3, 2], name: "7minor", suffix: "7min"),
    .init(intervals: [4, 4, 2, 2], name: "7augmented", suffix: "7aug"),
    .init(intervals: [3, 3, 4, 2], name: "7half-diminished", suffix: "7hdim"),
    .init(intervals: [4, 3, 3, 2], name: "7dominant", suffix: "7dom"),
    .init(intervals: [3, 4, 4, 1], name: "7minor-major", suffix: "7minmaj"),
    .init(intervals: [4, 4, 3, 1], name: "7augmented-major", suffix: "7augma"),
    .init(intervals: [2, 2, 3, 5], name: "9add", suffix: "9add"),
    .init(intervals: [2, 2, 3, 3, 2], name: "9", suffix: "9"),
    .init(intervals: [2, 1, 4, 3, 2], name: "9minor", suffix: "9min"),
    .init(intervals: [2, 2, 3, 4, 1], name: "9major", suffix: "9maj"),
    .init(intervals: [1, 3, 3, 3, 2], name: Note.flatTag + "9", suffix: "9-"),
    .init(intervals: [3, 1, 3, 3, 2], name: Note.sharpTag + "9", suffix: "9+"),
    .init(intervals: [4, 1, 2, 3, 2], name: "11(short)", suffix: "11"),
    .init(intervals: [2, 2, 1, 2, 3, 2], name: "11", suffix: "11"),
    .init(intervals: [4, 3, 2, 1, 2], name: "13(short)", suffix: "13"),
    .init(intervals: [2, 2, 1, 2, 2, 1, 2], name: "13", suffix: "13")
  ]

  struct NoteInterval {
    let note: Note
    let interval: Int
  }

  static func intervals(from: [Note]) -> [NoteInterval] {
    guard from.count > 1 else { return [] }
    let midi = from.map { $0.noteIndex }
    let ordered = midi.sorted()
    let rotated = ordered.dropFirst() + [ordered[0] + 12]
    return zip(ordered, rotated).map { NoteInterval(note: Note(midiNoteValue: $0.0), interval: $0.1 - $0.0) }
  }

  static func isCyclicEqual(first: [Int], second: [Int]) -> Bool {
    guard first.count == second.count else { return false }
    var secondStartingIndices: [Int] = []
    var index = 0
    let getStartingIndex: ((Int) -> Int?) = { second.dropFirst($0).firstIndex(of: first[0]) }
    while true {
      guard let pos = getStartingIndex(index) else { break }
      secondStartingIndices.append(pos)
      index += 1
    }

    guard !secondStartingIndices.isEmpty else { return false }

    let isEqualForStartingIndex: ((Int) -> Bool) = { startingIndex in
      var secondIndex = -1
      for firstIndex in 0..<first.count {
        let firstVal = first[firstIndex]
        if secondIndex == -1 {
          secondIndex = startingIndex
        } else {
          if secondIndex == second.count {
            secondIndex = 0
          }
          if firstVal != second[secondIndex] {
            return false
          }
        }
        secondIndex += 1
      }
      return true
    }

    return secondStartingIndices.first(where: isEqualForStartingIndex) != nil
  }

  static func detectChord(notes: [Note]) -> String? {
//    let noteIntervals = intervals(from: notes)
//    let intervals = noteIntervals.map { $0.interval }
//    let notes = noteIntervals.map { $0.note }
//    let filtered = known.enumerated().filter { (index: Int, chord: Chord) in
//      isCyclicEqual(a: chord.intervals, b: intervals)
//    }
    return nil
  }
}
