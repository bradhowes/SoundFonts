// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

/**
 A table view that shows the known MIDI devices.
 */
final class MIDIConnectionsTableViewController: UITableViewController {
  private var midi: MIDI!
  private var midiMonitor: MIDIMonitor!
  private var activeConnectionsObserver: NSKeyValueObservation?
  private var activeChannel: Int = -1
  private var monitorToken: NotificationObserver?

  func configure(midi: MIDI, midiMonitor: MIDIMonitor, activeChannel: Int) {
    self.midi = midi
    self.midiMonitor = midiMonitor
    self.activeChannel = activeChannel

    activeConnectionsObserver = midi.observe(\.activeConnections) { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.main.async { self.tableView.reloadData() }
    }
  }
}

// MARK: - View Management

extension MIDIConnectionsTableViewController {

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(MIDIConnectionsTableCell.self)
    tableView.registerHeaderFooter(MIDIConnectionsTableHeaderView.self)
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = self.midiMonitor.addConnectionActivityMonitor { payload in
      let accepted = self.accepting(channel: payload.channel)
      for (row, source) in self.midi.sourceConnections.enumerated() where source.uniqueId == payload.uniqueId {
        let indexPath = IndexPath(row: row, section: 0)
        if let cell: MIDIConnectionsTableCell = self.tableView.cellForRow(at: indexPath) {
          cell.channel.text = "\(payload.channel + 1)"
          let layer = cell.background.layer
          Self.midiSeenLayerChange(layer, accepted)
        }
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

extension MIDIConnectionsTableViewController {

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view: MIDIConnectionsTableHeaderView = tableView.dequeueReusableHeaderFooterView()
    return view
  }

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    midi.sourceConnections.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIConnectionsTableCell = tableView.dequeueReusableCell(at: indexPath)
    let source = midi.sourceConnections[indexPath.row]
    cell.name.text = source.displayName

    let connectionState = midiMonitor.connectionState(for: source.uniqueId)
    if let channel = source.channel {
      cell.channel.text = "\(channel + 1)"
    } else {
      cell.channel.text = "—"
    }

    cell.velocityStepper.minimumValue = 0
    cell.velocityStepper.maximumValue = 128

    if let fixedVelocity = connectionState.fixedVelocity {
      cell.velocityStepper.value = Double(fixedVelocity)
      cell.velocity.text = "\(fixedVelocity)"
    } else {
      cell.velocity.text = "Off"
      cell.velocityStepper.value = 128
    }

    cell.velocityStepper.tag = Int(source.uniqueId)
    if cell.velocityStepper.target(forAction: #selector(velocityStepperChanged(_:)), withSender: self) == nil {
      cell.velocityStepper.addTarget(self, action: #selector(velocityStepperChanged(_:)), for: .valueChanged)
    }

    cell.connected.isOn = source.connected
    cell.connected.tag = Int(source.uniqueId)
    if cell.connected.target(forAction: #selector(connectedStateChanged(_:)), withSender: cell.connected) == nil {
      cell.connected.addTarget(self, action: #selector(connectedStateChanged(_:)), for: .valueChanged)
    }
    return cell
  }

  @IBAction func resetMIDI(_ sender: Any) {
    let ac = UIAlertController(
      title: "Reset MIDI",
      message: """
          This will reset the MIDI state and knowledge for the app. Are you sure you wish to continue?
          """, preferredStyle: .alert)
    ac.addAction(
      UIAlertAction(title: "Yes", style: .default) { _ in
        self.midi.stop()
        MIDIRestart()
        self.midi.start()
      })
    ac.addAction(
      UIAlertAction(title: "Cancel", style: .cancel) { _ in
      })
    present(ac, animated: true)

    MIDIRestart()
  }

  @IBAction func velocityStepperChanged(_ sender: UIStepper) {
    let uniqueId = Int32(sender.tag)
    for (row, source) in self.midi.sourceConnections.enumerated() where source.uniqueId == uniqueId {
      guard let cell: MIDIConnectionsTableCell = tableView.cellForRow(at: .init(row: row, section: 0)) else {
        return
      }

      if sender.value == sender.minimumValue || sender.value == sender.maximumValue {
        cell.velocity.text = "Off"
        midiMonitor.setFixedVelocityState(for: uniqueId, velocity: nil)
      } else {
        cell.velocity.text = "\(Int(sender.value))"
        midiMonitor.setFixedVelocityState(for: uniqueId, velocity: UInt8(sender.value))
      }
    }
  }

  @IBAction func connectedStateChanged(_ sender: UISwitch) {
    let uniqueId = Int32(sender.tag)
    if sender.isOn {
      midiMonitor.setAutoConnectState(for: uniqueId, autoConnect: true)
      _ = midi.connect(to: uniqueId)
    } else {
      midiMonitor.setAutoConnectState(for: uniqueId, autoConnect: false)
      midi.disconnect(from: uniqueId)
    }
  }
}

// MARK: - MIDIMonitor Methods

extension MIDIConnectionsTableViewController {

  private func accepting(channel: Int) -> Bool {
    activeChannel == -1 || activeChannel == channel
  }

  public static func midiSeenLayerChange(_ layer: CALayer, _ accepted: Bool) {
    let color = accepted ? UIColor.systemTeal : UIColor.systemOrange
    let animator = CAKeyframeAnimation(keyPath: "backgroundColor")
    animator.values = [color.cgColor, UIColor.clear.cgColor]
    animator.keyTimes = [0.0, 1.0]
    animator.duration = 0.5
    layer.removeAllAnimations()
    layer.add(animator, forKey: "MIDI Seen")
  }
}
