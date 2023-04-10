// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI

/**
 Holds MIDI controller assignment information for an action.
 */
public class MIDIControllerActionState: Codable {

  /// The action that can be assigned a controller
  let action: MIDIControllerAction
  /// The current controller assigned to the action
  var assigned: Int?
  /// The type of controller assigned
  var kind: MIDIControllerActionKind?

  /// The name to show for the assignment
  var assignedName: String {
    guard let rawValue = assigned, let kind = kind else { return "" }
    guard let cc = MIDICC(rawValue: rawValue) else { return "CC \(rawValue)\(kind.displayName)"}
    return cc.name + " [CC \(rawValue)\(kind.displayName)]"
  }

  public init(action: MIDIControllerAction, assigned: Int? = nil, kind: MIDIControllerActionKind? = nil) {
    self.action = action
    self.assigned = assigned
    self.kind = kind
  }
}
