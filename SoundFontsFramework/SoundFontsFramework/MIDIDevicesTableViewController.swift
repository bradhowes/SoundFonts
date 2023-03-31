// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

/**
 A table view that shows the known MIDI devices.
 */
final class MIDIDevicesTableViewController: UITableViewController {

  private var settings: Settings!
  private var midi: MIDI!
  private var midiMonitor: MIDIMonitor!

  private var activeConnectionsObserver: NSKeyValueObservation?
  private var channelsObserver: NSKeyValueObservation?
  private var activeChannel: Int = -1
  private var monitorToken: NotificationObserver?

  func configure(settings: Settings, midi: MIDI, midiMonitor: MIDIMonitor, activeChannel: Int) {
    self.settings = settings
    self.midi = midi
    self.midiMonitor = midiMonitor
    self.activeChannel = activeChannel

    activeConnectionsObserver = midi.observe(\.activeConnections) { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.main.async { self.tableView.reloadData() }
    }

    channelsObserver = midi.observe(\.channels) { [weak self] _, _ in
      guard let self = self else { return }
      DispatchQueue.main.async { self.tableView.reloadData() }
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
    monitorToken = self.midiMonitor.addMonitor { payload in
      let accepted = self.accepting(channel: payload.channel)
      for (row, source) in self.midi.sourceConnections.enumerated() where source.uniqueId == payload.uniqueId {
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
    midi.sourceConnections.count
  }

  private func connectedSettingKey(for uniqueId: MIDIUniqueID) -> String { "midiAudoConnect_\(uniqueId)" }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: MIDIDeviceTableCell = tableView.dequeueReusableCell(at: indexPath)
    let source = midi.sourceConnections[indexPath.row]
    let autoConnectDefault = settings.autoConnectNewMIDIDeviceEnabled
    let autoConnect = settings.get(key: connectedSettingKey(for: source.uniqueId), defaultValue: autoConnectDefault)
    cell.update(midi: midi, sourceConnection: source, autoConnect: autoConnect)
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
