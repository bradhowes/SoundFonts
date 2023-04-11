// Copyright © 2023 Brad Howes. All rights reserved.

import os

final public class MIDIControllerState {

  let identifier: Int
  let name: String
  var lastValue: Int?
  var allowed: Bool

  public init(identifier: Int, allowed: Bool) {
    self.identifier = identifier
    self.name = MIDICC(rawValue: identifier)?.name ?? ""
    self.lastValue = nil
    self.allowed = allowed
  }
}
