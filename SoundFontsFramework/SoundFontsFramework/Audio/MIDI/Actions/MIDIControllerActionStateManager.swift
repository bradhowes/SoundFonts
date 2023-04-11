// Copyright © 2023 Brad Howes. All rights reserved.

import os.log
import CoreMIDI

public class MIDIControllerActionStateManager {
  private lazy var log = Logging.logger("MIDIControllerActionStateManager")

  public typealias ControllerActionIndexMap = [Int: Set<Int>]
  public private(set) var actions = [MIDIControllerActionState]()
  public private(set) var lookup: ControllerActionIndexMap = .init()

  private let settings: Settings

  public init(settings: Settings) {
    self.settings = settings
    (self.actions, self.lookup) = Self.generateActions(settings: settings)
  }

  static func generateActions(settings: Settings) -> ([MIDIControllerActionState], ControllerActionIndexMap) {
    let data: Data = settings.get(key: "controllerActionStateConfig", defaultValue: Data())
    return buildLookup(restoreFrom(data: data) ?? createDefault())
  }

  static func createDefault() -> [MIDIControllerActionState] {
    MIDIControllerAction.allCases.map { MIDIControllerActionState(action: $0) }
  }

  static func restoreFrom(data: Data) -> [MIDIControllerActionState]? {
    guard var restored = try? JSONDecoder().decode(Array<MIDIControllerActionState>.self, from: data) else {
      return nil
    }

    guard restored.count != MIDIControllerAction.allCases.count else { return restored }

    let mapping = Dictionary(uniqueKeysWithValues: restored.map { ($0.action, $0) })
    restored = []
    for action in MIDIControllerAction.allCases {
      if let value = mapping[action] {
        restored.append(value)
      } else {
        restored.append(.init(action: action))
      }
    }

    return restored
  }

  static func buildLookup(_ actions: [MIDIControllerActionState]) -> ([MIDIControllerActionState], ControllerActionIndexMap) {
    var lookup = ControllerActionIndexMap()
    for (index, each) in actions.enumerated() {
      if let cc = each.assigned {
        var value = lookup[cc] ?? .init()
        if value.insert(index).inserted {
          lookup[cc] = value
        }
      }
    }

    return (actions, lookup)
  }

  public func assign(controller: Int?, kind: MIDIControllerActionKind?, to action: MIDIControllerAction) {
    os_log(.info, log: log, "assign - %d %s %s", controller ?? -1, kind.debugDescription, action.displayName)
    guard let actionIndex = actions.firstIndex(where: { $0.action == action }) else { return }
    let actionState = actions[actionIndex]

    // If another controller was assigned to this action, remove it first.
    if let controller = actionState.assigned {
      lookup[controller]?.remove(actionIndex)
    }

    actionState.assigned = controller
    actionState.kind = kind

    if let controller = controller {
      var value = lookup[controller] ?? .init()
      if value.insert(actionIndex).inserted {
        lookup[controller] = value
      }
    }

    if let config = try? JSONEncoder().encode(self.actions) {
      settings.set(key: "controllerActionStateConfig", value: config)
    }
  }
}
