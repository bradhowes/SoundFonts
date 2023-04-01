// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

final class MIDIControllerTableCell: UITableViewCell, ReusableView, NibLoadableView {
  private weak var receiver: MIDIReceiver?
  private var controller: UInt8!

  @IBOutlet weak var name: UILabel!
  let allowed = UISwitch()

  public override func awakeFromNib() {
    super.awakeFromNib()
    translatesAutoresizingMaskIntoConstraints = true
    allowed.tintColor = UIColor.systemTeal
    allowed.addTarget(self, action: #selector(allowedStateChanged(_:)), for: .valueChanged)
  }

  public func update(receiver: MIDIReceiver, title: String?, subtitle: String, controller: UInt8, allowed: Bool) {
    var content = defaultContentConfiguration()
    if title != nil {
      content.text = title
      content.secondaryText = subtitle
    } else {
      content.text = subtitle
      content.secondaryText = " "
    }

    self.receiver = receiver
    self.contentConfiguration = content
    self.controller = controller
    self.allowed.isOn = allowed
    self.accessoryView = self.allowed
  }

  @IBAction func allowedStateChanged(_ sender: UISwitch) {
    receiver?.allowedStateChanged(controller: controller, allowed: sender.isOn)
  }
}
