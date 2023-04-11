// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

/**
 A table view that shows the known MIDI devices.
 */
final class MIDIControllersTableViewController: UITableViewController {
  private var midiEventRouter: MIDIEventRouter!
  private var monitorToken: NotificationObserver?

  func configure(midiEventRouter: MIDIEventRouter) {
    self.midiEventRouter = midiEventRouter
  }
}

// MARK: - View Management

extension MIDIControllersTableViewController {

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(MIDIControllersTableCell.self)
    tableView.registerHeaderFooter(MIDIControllersTableHeaderView.self)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = MIDIEventRouter.monitorControllerActivity { payload in
      let indexPath = IndexPath(row: Int(payload.controller), section: 0)
      self.tableView.reloadRows(at: [indexPath], with: .none)
    }
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    monitorToken?.forget()
    monitorToken = nil
  }
}

// MARK: - Table View Methods

extension MIDIControllersTableViewController {

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view: MIDIControllersTableHeaderView = tableView.dequeueReusableHeaderFooterView()
    return view
  }

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    128
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIControllersTableCell = tableView.dequeueReusableCell(at: indexPath)
    let midiControllerState = midiEventRouter.midiControllerState[indexPath.row]
    cell.identifier.text = "\(indexPath.row)"
    cell.name.text = midiControllerState.name

    let assignments = (midiEventRouter.midiControllerActionStateManager.lookup[indexPath.row] ?? []) .map {
      midiEventRouter.midiControllerActionStateManager.actions[$0].action.displayName
    }.joined(separator: ", ")

    cell.action.text = assignments
    cell.value.text = midiControllerState.lastValue != nil ? "\(midiControllerState.lastValue!)" : ""

    cell.used.isOn = midiControllerState.allowed
    cell.used.tag = indexPath.row
    if cell.used.target(forAction: #selector(allowedStateChanged(_:)), withSender: cell.used) == nil {
      cell.used.addTarget(self, action: #selector(allowedStateChanged(_:)), for: .valueChanged)
    }
    return cell
  }

  @IBAction func disableAll(_ sender: Any) {
    for controller in 0..<128 {
      midiEventRouter.allowedStateChanged(controller: controller, allowed: false)
      tableView.reloadData()
    }
  }

  @IBAction func enableAll(_ sender: Any) {
    for controller in 0..<128 {
      midiEventRouter.allowedStateChanged(controller: controller, allowed: true)
      tableView.reloadData()
    }
  }

  @IBAction func allowedStateChanged(_ sender: UISwitch) {
    midiEventRouter.allowedStateChanged(controller: sender.tag, allowed: sender.isOn)
  }

  private func controllerAllowedSettingName(controller: Int) -> String { "controllerAllowed\(controller)" }
}
