// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 Delegate for keyboard note events.
 */
protocol KeyboardManagerDelegate: class {
    
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
protocol KeyboardManager: class {
    
    /// Delegate to receive notifications of note ON/OFF events
    var delegate: KeyboardManagerDelegate? { get set }

    /// The value of the first note shown on the keyboard
    var lowestNote: Note { get set }
    
    /// THe value of the last note shown on the keyboard
    var highestNote: Note { get }

    /**
     Command the keyboard to release any pressed keys
     */
    func releaseAllKeys()
}
