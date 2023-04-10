// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI

public class MIDIControllerActionStateManager {

  public private(set) var actions = [MIDIControllerActionState]()
  private let settings: Settings

  public init(settings: Settings) {
    self.settings = settings
    for action in MIDIControllerAction.allCases {
      actions.append(MIDIControllerActionState(action: action,
                                               assigned: actionController(for: action),
                                               kind: actionControllerKind(for: action)))
    }
  }
}

private extension MIDIControllerActionStateManager {

  func actionControllerKey(for action: MIDIControllerAction) -> String { "actionController\(action)" }
  func actionControllerKindKey(for action: MIDIControllerAction) -> String { "actionControllerKind\(action)" }

  func actionController(for action: MIDIControllerAction) -> MIDICC? {
    settings.get(key: actionControllerKey(for: action), defaultValue: nil)
  }

  func actionControllerKind(for action: MIDIControllerAction) -> MIDIControllerActionKind? {
    settings.get(key: actionControllerKindKey(for: action), defaultValue: nil)
  }

  func setActionController(for action: MIDIControllerAction, value: MIDICC?) {
    settings.set(key: actionControllerKey(for: action), value: value)
  }

  func actionControllerKind(for action: MIDIControllerAction, value: MIDIControllerActionKind?) {
    settings.set(key: actionControllerKindKey(for: action), value: value)
  }
}
