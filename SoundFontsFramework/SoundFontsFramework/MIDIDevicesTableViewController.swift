// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI

/**
 A table view that shows the known MIDI devices.
 */
final class MIDIDevicesTableViewController: UITableViewController {

  private var devices = [MIDI.DeviceState]() { didSet { self.tableView.reloadData() } }
  private var activeConnectionsObserver: NSKeyValueObservation?
  private var channelsObserver: NSKeyValueObservation?
  private var activeChannel: Int = -1
  private var monitorToken: NotificationObserver?

  func configure(_ devices: [MIDI.DeviceState], _ activeChannel: Int) {
    self.devices = devices
    self.activeChannel = activeChannel
  }
}

// MARK: - View Management

extension MIDIDevicesTableViewController {

  override public func viewDidLoad() {
    activeConnectionsObserver = MIDI.sharedInstance.observe(\.activeConnections) { [weak self] _, _ in
      self?.devices = MIDI.sharedInstance.devices
    }
    channelsObserver = MIDI.sharedInstance.observe(\.channels) { [weak self] _, _ in
      DispatchQueue.main.async {
        self?.tableView.reloadData()
      }
    }
    super.viewDidLoad()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = MIDI.sharedInstance.addMonitor { data in
      let accepted = self.accepting(channel: data.channel)
      for (row, deviceState) in self.devices.enumerated() where deviceState.uniqueId == data.uniqueId {
        let indexPath = IndexPath(row: row, section: 0)
        if let cell = self.tableView.cellForRow(at: indexPath) {
          let layer = cell.contentView.layer
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

extension MIDIDevicesTableViewController {

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    devices.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "deviceState", for: indexPath)
    let deviceState = devices[indexPath.row]
    cell.textLabel?.text = deviceState.displayName

    let channelText: String
    if let channel = MIDI.sharedInstance.channels[deviceState.uniqueId] {
      channelText = "Chan: \(channel + 1)"
    } else {
      channelText = ""
    }

    cell.detailTextLabel?.text = "\(channelText)"
    return cell
  }

  @IBAction func resetMIDI(_ sender: Any) {
    MIDIRestart()
  }
}

// MARK: - MIDIMonitor Methods

extension MIDIDevicesTableViewController {

  private func accepting(channel: Int) -> Bool {
    activeChannel == -1 || activeChannel == channel
  }

  public static func midiSeenLayerChange(_ layer: CALayer, _ accepted: Bool) {
    let color = accepted ? UIColor.systemTeal : UIColor.systemOrange
    let animator = CABasicAnimation(keyPath: "backgroundColor")
    animator.fromValue = color.cgColor
    animator.toValue = UIColor.clear.cgColor
    layer.add(animator, forKey: "MIDI Seen")
  }
}
