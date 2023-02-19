// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI

public final class MIDIDeviceTableCell: UITableViewCell, ReusableView, NibLoadableView {
  private var midi: MIDI!
  private var endpoint: MIDIEndpointRef = MIDIEndpointRef()

  @IBOutlet weak var name: UILabel!
  let autoConnect = UISwitch()

  public override func awakeFromNib() {
    super.awakeFromNib()
    translatesAutoresizingMaskIntoConstraints = true

    autoConnect.tintColor = UIColor.systemTeal
    autoConnect.addTarget(self, action: #selector(connectedStateChanged(_:)), for: .valueChanged)
  }

  public func update(midi: MIDI, device: MIDI.DeviceState) {
    self.midi = midi
    self.endpoint = device.endpoint
    var name = device.displayName
    if let channel = device.channel {
      name += " - channel \(channel + 1)"
    }

    self.name.text = name
    self.autoConnect.isOn = device.autoConnect

    self.accessoryView = self.autoConnect
  }

  @IBAction func connectedStateChanged(_ sender: UISwitch) {
    if sender.isOn {
      midi.connect(endpoint: endpoint)
    } else {
      midi.disconnect(endpoint: endpoint)
    }
  }
}
