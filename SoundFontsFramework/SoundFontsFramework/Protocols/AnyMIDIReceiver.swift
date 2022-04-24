// Copyright © 2018 Brad Howes. All rights reserved.

import CoreMIDI
import Foundation
import os

/**
 Protocol for an object that processes supported MIDI messages. All methods of the protocol are optional; each has a
 default implementation that does nothing.
 */
public protocol AnyMIDIReceiver: AnyObject, KeyboardNoteProcessor {

  /**
   Command the keyboard to release any pressed keys on the given channel

   - parameter channel: the destination channel
   */
  func stopAllNotes()

  /**
   Update the note pressure of a playing note

   - parameter note: the MIDI note that was previous started
   - parameter pressure: the new pressure to use
   - parameter channel: the destination channel
   */
  func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8)

  /**
   Change a controller value

   - parameter controller: the controller to change
   - parameter value: the value to use
   - parameter channel: the destination channel
   */
  func setController(controller: UInt8, value: UInt8, channel: UInt8)

  /**
   Change the program/preset (0-127)

   - parameter program: the new program to use
   - parameter channel: the destination channel
   */
  func changeProgram(program: UInt8, channel: UInt8)

  /**
   Change the program/preset (0-127) and bank.

   - parameter program: the new program to use
   - parameter bankMSB: the MSB of the bank to use
   - parameter bankLSB: the LSB of the bank to use
   - parameter channel: the destination channel
   */
  func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8)

  /**
   Change the pressure for all active keys.

   - parameter pressure: the new pressure to use
   - parameter channel: the destination channel
   */
  func setPressure(pressure: UInt8, channel: UInt8)

  /**
   Update the pitch-bend controller to a new value

   - parameter value: the new pitch-bend value to use
   - parameter channel: the destination channel
   */
  func setPitchBend(value: UInt16, channel: UInt8)

  /**
   Process a 'raw' 1 byte MIDI message.

   - parameter midiStatus: the message status
   - parameter data1: the first byte of the message
   */
  func processMIDIEvent(status: UInt8, data1: UInt8)

  /**
   Process a 'raw' 2 byte MIDI message

   - parameter midiStatus: the message status
   - parameter data1: the first byte of the message
   - parameter data2: the second byte of the message
   */
  func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8)
}

extension AnyMIDIReceiver {
  public func startNote(note: UInt8, velocity: UInt8, channel: UInt8) {}
  public func stopNote(note: UInt8, velocity: UInt8, channel: UInt8) {}
  public func stopAllNotes() {}
  public func setNotePressure(note: UInt8, pressure: UInt8, channel: UInt8) {}
  public func setController(controller: UInt8, value: UInt8, channel: UInt8) {}
  public func changeProgram(program: UInt8, channel: UInt8) {}
  public func changeProgram(program: UInt8, bankMSB: UInt8, bankLSB: UInt8, channel: UInt8) {}
  public func setPressure(pressure: UInt8, channel: UInt8) {}
  public func setPitchBend(value: UInt16, channel: UInt8) {}
  public func processMIDIEvent(status: UInt8, data1: UInt8) {}
  public func processMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8) {}
}
