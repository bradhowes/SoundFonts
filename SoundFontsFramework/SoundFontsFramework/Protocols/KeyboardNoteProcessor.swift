// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 Entities that can start/stop note playing from a virtual keyboard
 */
public protocol KeyboardNoteProcessor {

  /**
   Start a note.

   - parameter note: the MIDI note to start
   - parameter velocity: the velocity of the note
   - parameter channel: the channel to operate on
   */
  func startNote(note: UInt8, velocity: UInt8, channel: UInt8)

  /**
   Stop a note.

   - parameter note: the MIDI note to stop
   - parameter channel: the channel to operate on
   */
  func stopNote(note: UInt8, channel: UInt8)
}
