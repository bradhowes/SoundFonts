// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

public final class MIDIDeviceTableCell: UITableViewCell, ReusableView, NibLoadableView {
  private var midi: MIDI!
  private var uniqueId: MIDIUniqueID = .init()

  @IBOutlet weak var name: UILabel!
  let autoConnect = UISwitch()

  public override func awakeFromNib() {
    super.awakeFromNib()
    translatesAutoresizingMaskIntoConstraints = true

    autoConnect.tintColor = UIColor.systemTeal
    autoConnect.addTarget(self, action: #selector(connectedStateChanged(_:)), for: .valueChanged)
  }

  public func update(midi: MIDI, sourceConnection: MIDI.SourceConnectionState, autoConnect: Bool) {
    self.midi = midi
    var name = sourceConnection.displayName
    if let channel = sourceConnection.channel {
      name += " - channel \(channel + 1)"
    }

    self.name.text = name
    self.autoConnect.isOn = autoConnect
    self.accessoryView = self.autoConnect
  }

  @IBAction func connectedStateChanged(_ sender: UISwitch) {
    if sender.isOn {
      if !midi.connect(to: uniqueId) {
        sender.isOn = false
      }
    } else {
      midi.disconnect(from: uniqueId)
    }
  }
}
