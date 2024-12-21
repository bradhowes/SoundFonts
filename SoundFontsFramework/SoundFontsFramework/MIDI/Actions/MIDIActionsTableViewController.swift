// Copyright © 2021 Brad Howes. All rights reserved.

import os.log
import UIKit
import CoreMIDI
import MorkAndMIDI

/**
 A table view that shows the assignments of SoundFont actions to MIDI controllers.
 */
final class MIDIActionsTableViewController: UITableViewController {
  private lazy var log: Logger = Logging.logger("MIDIActionsTableViewController")

  private var midiEventRouter: MIDIEventRouter!
  private var monitorToken: NotificationObserver?
  private var learningRow: Int?
  private var actions: [MIDIControllerActionState] { midiEventRouter.midiControllerActionStateManager.actions }
  private var learningValues = [UInt8]()

  enum ButtonState: String {
    case learning = "Learn"
    case stop = "Stop"
    case forget = "Forget"

    var textColor: UIColor {
      switch self {
      case .learning: return .systemTeal
      case .stop: return .systemRed
      case .forget: return .systemYellow
      }
    }
  }

  func configure(midiEventRouter: MIDIEventRouter) {
    self.midiEventRouter = midiEventRouter
  }
}

// MARK: - View Management

extension MIDIActionsTableViewController {

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(MIDIActionsTableCell.self)
    tableView.registerHeaderFooter(MIDIActionsTableHeaderView.self)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = MIDIEventRouter.monitorControllerActivity { [weak self] payload in
      guard let self = self, let row = self.learningRow else { return }
      self.trackController(controller: payload.controller, value: payload.value, for: row)
    }
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    learningRow = nil
    monitorToken?.forget()
    monitorToken = nil
  }
}

// MARK: - Table View Methods

extension MIDIActionsTableViewController {

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view: MIDIActionsTableHeaderView = tableView.dequeueReusableHeaderFooterView()
    return view
  }

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    actions.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIActionsTableCell = tableView.dequeueReusableCell(at: indexPath)
    let state = actions[indexPath.row]
    cell.name.text = state.action.displayName
    cell.controller.text = state.assignedName
    cell.learn.tag = indexPath.row
    updateLearningButton(cell.learn, state: buttonState(for: indexPath.row))
    if cell.learn.actions(forTarget: self, forControlEvent: .touchUpInside) == nil {
      cell.learn.addTarget(self, action: #selector(learnButtonPressed(_:)), for: .touchUpInside)
    }

    return cell
  }

  @IBAction func learnButtonPressed(_ sender: UIButton) {
    switch buttonState(for: sender.tag) {
    case .stop:
      if let cell: MIDIActionsTableCell = tableView.cellForRow(at: .init(row: sender.tag, section: 0)) {
        learningRow = nil
        learningValues.removeAll()
        updateLearningButton(cell.learn, state: .learning)
      }

    case .forget:
      removeAssign(row: sender.tag)

    case .learning:
      learningRow = sender.tag
      updateLearningButton(sender, state: .stop)
    }
  }
}

private extension MIDIActionsTableViewController {

  func buttonState(for row: Int) -> ButtonState {
    if learningRow == row {
      return .stop
    } else if actions[row].assigned != nil {
      return .forget
    } else {
      return .learning
    }
  }

  func updateLearningButton(_ button: UIButton, state: ButtonState) {
    button.setTitle(state.rawValue, for: .normal)
    button.setTitleColor(state.textColor, for: .normal)
  }

  func trackController(controller: UInt8, value: UInt8, for row: Int) {
    learningValues.append(value)

    // On/Off Switch?
    if learningValues.count >= 2 {
      let uniqueSorted = Set(learningValues).sorted()
      if uniqueSorted == [0, 127] {
        assign(controller: Int(controller), kind: .onOff, to: row)
        return
      }
    }

    if learningValues.count > 15 {
      let uniqueSorted = Set(learningValues).sorted()
      let kind: MIDIControllerActionKind
      if let last = uniqueSorted.last,
         let first = uniqueSorted.first,
         uniqueSorted.count < 15,
         (last - first) < 9 {
        kind = .relative // small changes around 64
      } else {
        kind = .absolute
      }
      assign(controller: Int(controller), kind: kind, to: row)
    }
  }

  func assign(controller: Int, kind: MIDIControllerActionKind, to row: Int) {
    midiEventRouter.midiControllerActionStateManager.assign(controller: controller,
                                                            kind: kind,
                                                            to: actions[row].action)
    learningRow = nil
    learningValues.removeAll()
    tableView.reloadRows(at: [.init(row: row, section: 0)], with: .automatic)
  }

  func removeAssign(row: Int) {
    midiEventRouter.midiControllerActionStateManager.assign(controller: nil, kind: nil, to: actions[row].action)
    learningRow = nil
    learningValues.removeAll()
    tableView.reloadRows(at: [.init(row: row, section: 0)], with: .automatic)
  }
}
