// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

final class MIDIConnectionsTableCell: UITableViewCell, ReusableView, NibLoadableView {
  @IBOutlet weak var background: UIView!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var channel: UILabel!
  @IBOutlet weak var velocity: UILabel!
  @IBOutlet weak var velocityStepper: UIStepper!
  @IBOutlet weak var connected: UISwitch!

  public override func awakeFromNib() {
    super.awakeFromNib()
    connected.onTintColor = UIColor.systemTeal

    velocityStepper.tintColor = UIColor.systemTeal
    velocityStepper.setDecrementImage(velocityStepper.decrementImage(for: .normal), for: .normal)
    velocityStepper.setIncrementImage(velocityStepper.incrementImage(for: .normal), for: .normal)
  }
}
