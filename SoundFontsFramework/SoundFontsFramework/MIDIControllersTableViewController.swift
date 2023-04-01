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

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = self.midiReceiver.addMonitor { payload in
      let indexPath = IndexPath(row: payload.controller, section: 0)
      if let cell = self.tableView.cellForRow(at: indexPath) {
        let layer = cell.contentView.layer
        Self.midiSeenLayerChange(layer, true)
      }
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

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    128
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIControllerTableCell = tableView.dequeueReusableCell(at: indexPath)
    let rawValue = UInt8(indexPath.row)
    let title: String? = MIDICC(rawValue: rawValue)?.name
    let subtitle = "CC \(rawValue)"
    cell.update(receiver: midiReceiver, title: title, subtitle: subtitle, controller: rawValue,
                allowed: midiReceiver.controllerAllowed(rawValue))
    return cell
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

  func allowedStateChanged(controller: Int, allowed: Bool) {
  }

  private func controllerAllowedSettingName(controller: Int) -> String { "controllerAllowed\(controller)" }
}

// MARK: - MIDIMonitor Methods

extension MIDIControllersTableViewController {

  public static func midiSeenLayerChange(_ layer: CALayer, _ accepted: Bool) {
    let color = accepted ? UIColor.systemTeal : UIColor.systemOrange
    let animator = CABasicAnimation(keyPath: "backgroundColor")
    animator.fromValue = color.cgColor
    animator.toValue = UIColor.clear.cgColor
    layer.add(animator, forKey: "MIDI Seen")
  }
}

private enum MIDICC: UInt8 {
  case bankSelect = 0
  case modulationWheel = 1
  case breathController = 2
  case footPedal = 4
  case portamentoTime = 5
  case volume = 7
  case balance = 8
  case pan = 10
  case expression = 11
  case effectController1 = 12
  case effectController2 = 13
  case damperPedal = 64
  case portamentoSwitch = 65
  case sostenutoPedal = 66
  case softPedal = 67
  case legatoSwitch = 68
  case hold2 = 69

  var name: String {
    switch self {
    case .bankSelect: return "Bank Select"
    case .modulationWheel: return "Modulation Wheel"
    case .breathController: return "Breath Controller"
    case .footPedal: return "Foot Pedal"
    case .portamentoTime: return "Portamento Time"
    case .volume: return "Volume"
    case .balance: return "Balance"
    case .pan: return "Pan"
    case .expression: return "Expression"
    case .effectController1: return "Effect Controller 1"
    case .effectController2: return "Effect Controller 2"
    case .damperPedal: return "Damper Pedal"
    case .portamentoSwitch: return "Portamento Switch"
    case .sostenutoPedal: return "Sostenuto Pedal"
    case .softPedal: return "Soft Pedal"
    case .legatoSwitch: return "Legato Switch"
    case .hold2: return "Hold 2"
    }
  }
}
