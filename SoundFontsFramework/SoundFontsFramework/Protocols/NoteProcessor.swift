// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

public protocol NoteProcessor {

  func noteOn(_ note: UInt8, velocity: UInt8)

  func noteOff(_ note: UInt8)
}
