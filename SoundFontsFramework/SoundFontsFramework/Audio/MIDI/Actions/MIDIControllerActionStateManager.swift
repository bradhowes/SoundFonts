// Copyright © 2023 Brad Howes. All rights reserved.

import os.log
import CoreMIDI

public class MIDIControllerActionStateManager {
  private lazy var log = Logging.logger("MIDIControllerActionStateManager")

  public private(set) var actions = [MIDIControllerActionState]()
  public private(set) var lookup = [Int: Int]()

  private let settings: Settings

  public init(settings: Settings) {
    self.settings = settings
    let config: Data = settings.get(key: "controllerActionStateConfig", defaultValue: Data())
    if let restored = try? JSONDecoder().decode(Array<MIDIControllerActionState>.self, from: config) {
      os_log(.info, log: log, "restored from settings - %d", restored.count)
      self.actions = restored
    } else {
      os_log(.info, log: log, "creating new array")
      for action in MIDIControllerAction.allCases {
        actions.append(MIDIControllerActionState(action: action))
      }
    }
    buildLookup()
  }

  private func buildLookup() {
    for (index, each) in actions.enumerated() {
      if let cc = each.assigned {
        lookup[cc] = index
      }
    }
  }
  public func assign(controller: Int?, kind: MIDIControllerActionKind?, to action: MIDIControllerAction) {
    os_log(.info, log: log, "assign - %d %s %s", controller ?? -1, kind.debugDescription, action.displayName)
    if let actionState = actions.first(where: { $0.action == action }) {
      actionState.assigned = controller
      actionState.kind = kind
      if let config = try? JSONEncoder().encode(self.actions) {
        settings.set(key: "controllerActionStateConfig", value: config)
      }
    }
  }
}
