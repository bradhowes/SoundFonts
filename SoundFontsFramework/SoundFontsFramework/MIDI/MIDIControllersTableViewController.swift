// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

/**
 A table view that shows the known MIDI devices.
 */
final class MIDIControllersTableViewController: UITableViewController {
  private var midiReceiver: MIDIReceiver!
  private var monitorToken: NotificationObserver?

  func configure(midiReceiver: MIDIReceiver) {
    self.midiReceiver = midiReceiver
  }
}

// MARK: - View Management

extension MIDIControllersTableViewController {

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(MIDIControllerTableCell.self)
    tableView.registerHeaderFooter(MIDIControllerTableHeaderView.self)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = MIDIReceiver.monitorActivity { payload in
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
    let view: MIDIControllerTableHeaderView = tableView.dequeueReusableHeaderFooterView()
    return view
  }

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    128
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIControllerTableCell = tableView.dequeueReusableCell(at: indexPath)
    let midiControllerState = midiReceiver.midiControllerState[indexPath.row]
    cell.identifier.text = "\(indexPath.row)"
    cell.name.text = midiControllerState.name

    cell.activity.setTitle(midiControllerState.action?.displayName ?? "Set…", for: .normal)
    cell.activity.addTarget(self, action: #selector(showActionView(_:)), for: .touchUpInside)

    cell.value.text = midiControllerState.lastValue != nil ? "\(midiControllerState.lastValue!)" : ""

    cell.used.isOn = midiControllerState.allowed
    cell.used.tag = indexPath.row
    if cell.used.target(forAction: #selector(allowedStateChanged(_:)), withSender: cell.used) == nil {
      cell.used.addTarget(self, action: #selector(allowedStateChanged(_:)), for: .valueChanged)
    }
    return cell
  }

  @IBAction func showActionView(_ sender: UIButton) {
    performSegue(withIdentifier: .midiControllerAction)
  }

  @IBAction func disableAll(_ sender: Any) {
    for controller in 0..<128 {
      midiReceiver.allowedStateChanged(controller: UInt8(controller), allowed: false)
      tableView.reloadData()
    }
  }

  @IBAction func enableAll(_ sender: Any) {
    for controller in 0..<128 {
      midiReceiver.allowedStateChanged(controller: UInt8(controller), allowed: true)
      tableView.reloadData()
    }
  }

  @IBAction func allowedStateChanged(_ sender: UISwitch) {
    midiReceiver.allowedStateChanged(controller: UInt8(sender.tag), allowed: sender.isOn)
  }

  private func controllerAllowedSettingName(controller: Int) -> String { "controllerAllowed\(controller)" }
}

// MARK: - MIDIMonitor Methods

extension MIDIControllersTableViewController: SegueHandler {

  public static func midiSeenLayerChange(_ layer: CALayer, _ accepted: Bool) {
    let color = accepted ? UIColor.systemTeal : UIColor.systemOrange
    let animator = CABasicAnimation(keyPath: "backgroundColor")
    animator.fromValue = color.cgColor
    animator.toValue = UIColor.clear.cgColor
    layer.add(animator, forKey: "MIDI Seen")
  }

  /// Segues that we support.
  public enum SegueIdentifier: String {
    case midiControllerAction
  }

  public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segueIdentifier(for: segue) {
    case .midiControllerAction:
      break
      // let destination = segue.destination as? MIDIControllersTableViewController
      // destination.configure(midi: midi, midiMonitor: midiMonitor, activeChannel: settings.midiChannel)
    }
  }
}
