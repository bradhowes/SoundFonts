//
//  Track.swift
//  Miles
//
//  Created by Brad Howes on 10/2/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation

/**
 A Track holds MIDI notes for a particular instrument. Internally is writes to a MusicTrack.
 */
public class Track {

    /// The container that will hold the MIDI notes
    private let track: MusicTrack
    /// The instrument that will play the notes
    public let instrument: Instrument

    /**
     Create new Track to hold a new MusicTrack for the given MusicSequence container.
    
     - parameter sequence: the MusicSequence that will hold the track
     - parameter instrument: the Insrument that will play the notes
     */
    init(sequence: MusicSequence, instrument: Instrument) {
        var mt: MusicTrack?
        let status = MusicSequenceNewTrack(sequence, &mt)
        if status != noErr {
            fatalError("failed MusicSequenceNewTrack - \(status)")
        }

        self.track = mt!
        self.instrument = instrument

        initializeMIDI()
    }

    /**
     Add some MIDI channel messages to the new MusicTrack.
     */
    private func initializeMIDI() {

        // Is all of this necessary? Perhaps if there is an external MIDI device connected to the network.
        // Bank select msb
        var chanmess = MIDIChannelMessage(status: 0xB0, data1: 0, data2: 0, reserved: 0) //MIDI Channel Message for status 176
        var status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
        if status != OSStatus(noErr) {
            print("creating bank select event \(status)")
        }
        
        // Bank select lsb
        chanmess = MIDIChannelMessage(status: 0xB0, data1: 32, data2: 0, reserved: 0) // MIDI Channel Message for status 176 / Data byte 1: 32-63 LSB of 0-31
        status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
        if status != OSStatus(noErr) {
            print("creating bank select event \(status)")
        }
        
        // program change. first data byte is the patch, the second data byte is unused for program change messages.
        // Status 192: Command value for Program Change message (https://docs.oracle.com/javase/7/docs/api/javax/sound/midi/ShortMessage.html#PROGRAM_CHANGE)
        chanmess = MIDIChannelMessage(status: 0xC0, data1: 0, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track, 0, &chanmess)
        if status != OSStatus(noErr) {
            print("creating program change event \(status)")
        }
    }

    /**
     Get a MIDINoteEvent from the instrument for a note/beat/duration combination. Add it to the track.
    
     - parameter note: the note to play
     - parameter beat: the beat to play it on
     - parameter duration: the duration to play the note
     */
    public func add(note: Note, onBeat beat: MusicTimeStamp, duration: Duration) {
        var msg = instrument.play(beat: beat, note: note, duration: duration)
        let status = MusicTrackNewMIDINoteEvent(track, beat, &msg)
        if status != noErr {
            print("Error creating new midi note event \(status)")
        }
    }
}
