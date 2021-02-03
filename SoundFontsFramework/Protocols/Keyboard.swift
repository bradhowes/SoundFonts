// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 Manages the state of the keyboard
 */
public protocol Keyboard: class {

    /// The value of the first note shown on the keyboard
    var lowestNote: Note { get set }

    /// The value of the last note shown on the keyboard
    var highestNote: Note { get }

    /// Set true if audio is currently muted on the device. Affects how the keys are rendered.
    var isMuted: Bool { get set }

    /**
     Command the keyboard to release any pressed keys
     */
    func releaseAllKeys()

    func noteIsOff(note: UInt8)

    func noteIsOn(note: UInt8)
}
