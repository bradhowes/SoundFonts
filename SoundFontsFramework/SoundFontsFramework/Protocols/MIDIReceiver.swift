// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import CoreMIDI
import os

/**
 Functionality we expect for entities that can receive MIDI messages.
 */
public protocol MIDIReceiver: AnyObject {

    /// The channel the controller listens on. If -1, then it wants msgs from ALL channels
    var channel: Int { get }

    /**
     Stop playing note.

     - parameter note: the MIDI note to stop
     */
    func noteOff(note: UInt8)

    /**
     Start playing a note.

     - parameter note: the MIDI note to play
     - parameter velocity: the velocity to use when playing
     */
    func noteOn(note: UInt8, velocity: UInt8)

    /**
     Command the keyboard to release any pressed keys
     */
    func releaseAllKeys()

    /**
     Update the key pressure of a playing note

     - parameter note: the MIDI note that was previous started
     - parameter pressure: the new pressure to use
     */
    func polyphonicKeyPressure(note: UInt8, pressure: UInt8)

    /**
     Change a controller value

     - parameter controller: the controller to change
     - parameter value: the value to use
     */
    func controlChange(controller: UInt8, value: UInt8)

    /**
     Change the program/preset (0-127)

     - parameter program: the new program to use
     */
    func programChange(program: UInt8)

    /**
     Change the whole pressure for the channel. Affects all playing notes.

     - parameter pressure: the new pressure to use
     */
    func channelPressure(pressure: UInt8)

    /**
     Update the pitch-bend controller to a new value

     - parameter value: the new pitch-bend value to use
     */
    func pitchBendChange(value: UInt16)
}

extension MIDIReceiver {

    /**
     Process a collection of MIDI messages for the controller.

     - parameter msgs: the MIDIMsg collection
     */
    public func process(_ msgs: [MIDIMsg], when: MIDITimeStamp ) {
        for msg in msgs {
            switch msg {
            case let .noteOff(note, _): self.noteOff(note: note)
            case let .noteOn(note, velocity): self.noteOn(note: note, velocity: velocity)
            case let .polyphonicKeyPressure(note, pressure): self.polyphonicKeyPressure(note: note, pressure: pressure)
            case let .controlChange(controller, value): self.controlChange(controller: controller, value: value)
            case let .programChange(program): self.programChange(program: program)
            case let .channelPressure(pressure): self.channelPressure(pressure: pressure)
            case let .pitchBendChange(value): self.pitchBendChange(value: value)
            }
        }
    }
}
