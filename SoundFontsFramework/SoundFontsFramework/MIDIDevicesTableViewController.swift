// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI

/**
 A table view that shows the known MIDI devices.
 */
final class MIDIDevicesTableViewController: UITableViewController {

  private var midi: MIDI!
  private var devices = [MIDI.DeviceState]() {
    didSet {
      if self.isViewLoaded {
        self.tableView.reloadData()
      }
    }
  }

  private var activeConnectionsObserver: NSKeyValueObservation?
  private var channelsObserver: NSKeyValueObservation?
  private var activeChannel: Int = -1
  private var monitorToken: NotificationObserver?

  func configure(midi: MIDI, activeChannel: Int) {
    self.midi = midi
    self.devices = midi.devices
    self.activeChannel = activeChannel

    activeConnectionsObserver = midi.observe(\.activeConnections) { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.devices = self.midi.devices
      }
    }

    channelsObserver = midi.observe(\.channels) { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.devices = self.midi.devices
      }
    }
  }
}

// MARK: - View Management

extension MIDIDevicesTableViewController {

  override public func viewDidLoad() {
    let footer = UILabel()
    tableView.tableFooterView = footer
    footer.text = "This is a test."
    super.viewDidLoad()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    monitorToken = self.midi.addMonitor { data in
      let accepted = self.accepting(channel: data.channel)
      for (row, deviceState) in self.devices.enumerated() where deviceState.endpoint == data.endpoint {
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
    let cell: MIDIDeviceTableCell = tableView.dequeueReusableCell(at: indexPath)
    let deviceState = devices[indexPath.row]
    cell.update(midi: midi, device: deviceState)
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
        self.midi.reset()
        MIDIRestart()
      })
    ac.addAction(
      UIAlertAction(title: "Cancel", style: .cancel) { _ in
      })
    present(ac, animated: true)

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
