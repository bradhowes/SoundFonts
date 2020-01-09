// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 Delegate for keyboard note events.
 */
public protocol KeyboardDelegate: class {

    /**
     Notification of a note "ON" event
    
     - parameter note: the note that is pressed
     */
    func noteOn(_ note: Note)

    /**
     Notification of a note "OFF" event
    
     - parameter note: the note that was released
     */
    func noteOff(_ note: Note)
}

/**
 Manages the state of the keyboard
 */
public protocol Keyboard: class {

    /// Delegate to receive notifications of note ON/OFF events
    var delegate: KeyboardDelegate? { get set }

    /// The value of the first note shown on the keyboard
    var lowestNote: Note { get set }

    /// The value of the last note shown on the keyboard
    var highestNote: Note { get }

    /// Set to true if audio is currently muted on the device. Affects how the keys are rendered.
    var isMuted: Bool { get set}

    /**
     Command the keyboard to release any pressed keys
     */
    func releaseAllKeys()
}
