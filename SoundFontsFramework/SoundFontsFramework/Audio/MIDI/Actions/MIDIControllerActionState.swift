// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI

public class MIDIControllerActionState {

  let action: MIDIControllerAction
  var assigned: MIDICC?
  var kind: MIDIControllerActionKind?

  public init(action: MIDIControllerAction, assigned: MIDICC?, kind: MIDIControllerActionKind?) {
    self.action = action
    self.assigned = assigned
    self.kind = kind
  }
}
