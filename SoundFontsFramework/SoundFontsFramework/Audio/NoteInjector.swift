// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import os

/// Submit a sequence of MIDI events to play a A4 note. Used when switching presets.
final class NoteInjector {
  private let log: Logger = Logging.logger("NoteInjector")
  private let note: UInt8 = 69  // A4
  private let noteOnDuration = 0.5
  private let noteVelocity: UInt8 = 32
  private let playingQueue = DispatchQueue(label: "NoteInjector.playingQueue", qos: .userInitiated,
                                           target: DispatchQueue.global(qos: .userInitiated))
  private let settings: Settings
  private var workItems = [DispatchWorkItem]()

  init(settings: Settings) {
    self.settings = settings
  }

  /**
   Post MIDI commands to the synth to play a short note.

   - parameter synth: the synth to command
   */
  func post(to synth: AnyMIDISynth) {
    guard settings.playSample == true else { return }
    workItems.forEach { $0.cancel() }

    let note = self.note
    let noteVelocity = self.noteVelocity
    let noteOn = DispatchWorkItem { synth.noteOn(note: note, velocity: noteVelocity) }

    // NOTE: for some reason, executing this without any delay does not work.
    playingQueue.asyncAfter(deadline: .now() + 0.025, execute: noteOn)

    let noteOff = DispatchWorkItem { synth.noteOff(note: note, velocity: 0) }
    playingQueue.asyncAfter(deadline: .now() + noteOnDuration, execute: noteOff)

    workItems = [noteOn, noteOff]
  }

  /**
   Post MIDI commands to an audio unit to play a short note.

   - parameter audioUnit: the audio unit to command
   */
  func post(to audioUnit: AUAudioUnit) {
    log.debug("post BEGIN")
    workItems.forEach { $0.cancel() }

    guard settings.playSample == true,
          let noteBlock = audioUnit.scheduleMIDIEventBlock
    else {
      return
    }

    let noteOnCommand: UInt8 = 0x90
    let note = UInt8(self.note)
    let velocity: UInt8 = 64

    let noteOnEmitter = DispatchWorkItem {
      let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
      bytes[0] = noteOnCommand
      bytes[1] = note
      bytes[2] = velocity
      // audioUnit.auAudioUnit.scheduleMIDIEventBlock?(AUEventSampleTimeImmediate, 0, 3, bytes)
      noteBlock(AUEventSampleTimeImmediate, 0, 3, bytes)
      bytes.deallocate()
    }

    let noteOffEmitter = DispatchWorkItem {
      let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
      bytes[0] = noteOnCommand
      bytes[1] = note
      bytes[2] = 0 // no velocity == note off
      noteBlock(AUEventSampleTimeImmediate, 0, 3, bytes)
      bytes.deallocate()
    }

    workItems = [noteOnEmitter, noteOffEmitter]

    let dispatchTime: DispatchTime = .now() + 0.2
    playingQueue.asyncAfter(deadline: dispatchTime, execute: noteOnEmitter)
    playingQueue.asyncAfter(deadline: dispatchTime + noteOnDuration, execute: noteOffEmitter)

    log.debug("post END")
  }
}
