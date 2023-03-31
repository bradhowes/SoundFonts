// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

final class MIDIDeviceTableCell: UITableViewCell, ReusableView, NibLoadableView {
  private weak var controller: MIDIDevicesTableViewController?
  private var uniqueId: MIDIUniqueID = .init()

  @IBOutlet weak var name: UILabel!
  let connected = UISwitch()

  public override func awakeFromNib() {
    super.awakeFromNib()
    translatesAutoresizingMaskIntoConstraints = true
    connected.tintColor = UIColor.systemTeal
    connected.addTarget(self, action: #selector(connectedStateChanged(_:)), for: .valueChanged)
  }

  public func update(controller: MIDIDevicesTableViewController, sourceConnection: MIDI.SourceConnectionState,
                     connected: Bool) {
    self.controller = controller
    var name = sourceConnection.displayName
    if let channel = sourceConnection.channel {
      name += " - channel \(channel + 1)"
    }

    self.name.text = name
    self.uniqueId = sourceConnection.uniqueId
    self.connected.isOn = connected
    self.accessoryView = self.connected
  }

  @IBAction func connectedStateChanged(_ sender: UISwitch) {
    controller?.changeConnectedState(uniqueId: uniqueId, connect: sender.isOn)
  }
}
