// Copyright © 2021 Brad Howes. All rights reserved.

import CoreMIDI

public protocol MIDIMonitor: AnyObject {
  func seen(uniqueId: MIDIUniqueID)
}
