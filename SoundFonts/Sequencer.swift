
//
//  File.swift
//  Miles
//
//  Created by Lalo Martínez on 3/21/18.
//  Copyright © 2018 Lalo Martínez. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

/**
 A Sequencer holds one or more Track objects that define the notes that instruments will play.
 */
public class Sequencer {

    /// Internal AVAudioSequencer that manages the tracks
    private var sequencer: AVAudioSequencer
    /// Internal MusicSequence object that holds MusicTrack objects
    private var sequence: MusicSequence
    /// Collection of Track objects that have been added and populated with notes
    private var tracks: [Track] = []

    /// Obtain a reference to the raw track data
    private var data: Data {
        get {
            var status = OSStatus(noErr)
            var data:Unmanaged<CFData>?
            status = MusicSequenceFileCreateData(sequence,
                                                 MusicSequenceFileTypeID.midiType,
                                                 MusicSequenceFileFlags.eraseFile,
                                                 480, &data)
            if status != noErr {
                fatalError("failed MusicSequenceFileCreateData - \(status)")
            }

            let ns: Data = data!.takeUnretainedValue() as Data
            data!.release()

            return ns
        }
    }
    
    /// The tempo of the sequence that will play
    public let tempo: Double
    /// The overall duration of the sequence
    public private(set) var duration: TimeInterval = 0.0

    /**
     Create a new Sequencer instance.
    
     - parameter engine: the AVAudioEngine instance to connect to
     - parameter tempo: the tempo (BPM) of the music to play
     */
    public init(engine: AVAudioEngine, withTempo tempo: Double) {
        self.sequencer = AVAudioSequencer(audioEngine: engine)

        var ms: MusicSequence?
        var status = NewMusicSequence(&ms)
        if status != noErr {
            fatalError("failed NewMusicSequence - \(status)")
        }

        self.sequence = ms!
        self.tempo = tempo

        // Set tempo track -- necessary?
        var tempoTrack: MusicTrack?
        status = MusicSequenceGetTempoTrack(sequence, &tempoTrack)
        if status != noErr {
            fatalError("failed MusicSequenceGetTempoTrack - \(status)")
        }

        status = MusicTrackNewExtendedTempoEvent(tempoTrack!, 0, tempo)
        if status != noErr {
            fatalError("failed MusicTrackNewExtendedTempoEvent - \(status)")
        }
    }

    /**
     Create a new Track and fill it with notes for a given instrument to play. The notes
     come from an arranger.
    
     - parameter instrument: the instrument that will play the notes
     - parameter arrange: the note generator
     */
    public func populate(instrument: Instrument, withArrangement arrange: (Track) -> Void) {
        let track = Track(sequence: sequence, instrument: instrument)
        tracks.append(track)
        arrange(track)
    }
    
    /**
     Complete the MIDI note generating process by creating AVAudioSequencer tracks from the MIDI data collected
     so far, and for each track, link it to an AVAudioUnitSampler from an Instrument.
     */
    public func complete() {
        try! sequencer.load(from: data)
        zip(sequencer.tracks, tracks).forEach { $0.0.destinationAudioUnit = $0.1.instrument.sampler.ausampler; }
        duration = sequencer.tracks.map { $0.lengthInSeconds }.max()!
        sequencer.prepareToPlay()
    }
    
    /**
     Start playback of the recoded MIDI notes.
     */
    public func start() {
        sequencer.currentPositionInBeats = TimeInterval(0)
        try! sequencer.start()
    }

    /**
     Stop playback of the recorded MIDI notes.
     */
    public func stop() {
        sequencer.stop()
    }

    /// Determine if the sequencer is playing. If the play position is past the recorded duration,
    /// stop the playback.
    public var isPlaying: Bool {
        print("\(sequencer.isPlaying) - \(sequencer.currentPositionInSeconds)")
        if sequencer.isPlaying && sequencer.currentPositionInSeconds >= duration {
            print("stpppoing")
            sequencer.currentPositionInSeconds = 0.0
            sequencer.stop()
        }
        return sequencer.isPlaying
    }
}
