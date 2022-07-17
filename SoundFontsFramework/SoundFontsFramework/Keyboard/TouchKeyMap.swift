// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Mapping of UITouch instances from touch events to the Key instances that are played by the touches.
internal struct TouchKeyMap {
  private let noteVelocity: UInt8
  private let noteChannel: UInt8

  /// The entity that processes key touches as MIDI notes
  var processor: KeyboardNoteProcessor?

  /**
   Construct new entity.

   - parameter noteVelocity: the velocity to use when starting a MIDI note
   - parameter noteChannel: the channel to use for the MIDI note commands
   */
  init(noteVelocity: UInt8 = 64, noteChannel: UInt8 = 0) {
    self.noteVelocity = noteVelocity
    self.noteChannel = noteChannel
  }

  private var touchedKeys = [UITouch: Key]()

  /**
   Remove all assignments.
   */
  mutating func releaseAll() {
    touchedKeys.forEach { releaseKey($0.1) }
    touchedKeys.removeAll()
  }

  /**
   Release any key that is attached to the given touch.

   - parameter touch: the touch to remove
   */
  mutating func release(_ touch: UITouch) {
    guard let key = touchedKeys[touch] else { return }
    releaseKey(key)
    touchedKeys.removeValue(forKey: touch)
  }

  /**
   Assign a key to the given touch. If the touch is already assigned, release the previous assignment.

   - parameter touch: the touch to attach to
   - parameter key: the key to press
   - returns: true if a new note was started
   */
  mutating func assign(_ touch: UITouch, key: Key) -> Bool {
    if let previous = touchedKeys[touch] {
      guard previous.note != key.note else { return false }
      releaseKey(previous)
    }

    activateKey(key)
    touchedKeys[touch] = key
    return true
  }
}

extension TouchKeyMap {

  private func activateKey(_ key: Key) {
    guard !key.pressed else { return }
    key.pressed = true
    processor?.startNote(note: UInt8(key.note.midiNoteValue), velocity: noteVelocity, channel: noteChannel)
  }

  private func releaseKey(_ key: Key) {
    guard key.pressed else { return }
    key.pressed = false
    processor?.stopNote(note: UInt8(key.note.midiNoteValue), velocity: 0, channel: noteChannel)
  }
}
