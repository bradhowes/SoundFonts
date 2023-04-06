// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

final class MIDIControllerTableCell: UITableViewCell, ReusableView, NibLoadableView {
  @IBOutlet weak var identifier: UILabel!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var value: UILabel!
  @IBOutlet weak var used: UISwitch!

  public override func awakeFromNib() {
    super.awakeFromNib()
    // translatesAutoresizingMaskIntoConstraints = true
    used.onTintColor = UIColor.systemTeal
  }
}
