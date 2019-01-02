//
//  Instrument.swift
//  Miles
//
//  Created by Lalo Martínez on 3/26/18.
//  Copyright © 2018 Lalo Martínez. All rights reserved.
//

import AVFoundation

/**
 Interface for all instruments. An instrument has a particular sound which comes from a
 Sampler instance. When creating a new performance via `createArrangement` method, the instrument
 will rely on a Sequence.Progression configuration that will generate the notes to play, but the
 Instrument will control the actual peformance characteristics of the notes via its `play` method.
 */
public protocol Instrument: class, Drawable {

    /// The source of the sounds for this instrument
    var sampler: Sampler { get }
    /// The canvas to draw in while playing notes
    var canvas: MilesCanvas? { get set }

    /**
     Uses the instrument's algorithm to create a music sequence based on the specified harmonization, chords and instrument type.

     - parameter sequencer: where to record the MIDI notes
     - parameter progression: A tuple with the most important info about the sequence - (harmonization: `Harmonization`, steps: `[Int]`)
     */
    func createArrangement(sequencer: Sequencer, progression: Sequence.Progression)

    /**
     Generate and return a MIDINoteMessage that can be added to a Track/MusicTrack for this instrument.
     Note that the instrument can modify and/or ignore any of the values. These are only suggestions
     provided by an Improviser. That said, the `note` value probably should remain the same, and the
     `beat` value should only deviate slightly if at all.

     - parameter beat: when to play the note
     - parameter note: what note to play
     - parameter duration: how long to play the note
     - returns: new MIDINoteMessage instance
     */
    func play(beat: MusicTimeStamp, note: Note, duration: Duration) -> MIDINoteMessage
}
