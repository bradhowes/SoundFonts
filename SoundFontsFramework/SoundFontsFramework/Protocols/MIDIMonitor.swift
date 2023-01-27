// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI

/**
 Protocol for an object that monitors MIDI input activity
 */
public protocol MIDIMonitor: AnyObject {

  /**
   Notification invoked when there is an incoming MIDI message. NOTE: this is called on a background
   thread.

   - parameter uniqueId: the unique ID of the MIDI endpoint that sent the message
   - parameter channel: the channel found in the MIDI message
   */
  func seen(uniqueId: MIDIUniqueID, channel: UInt8)
}
