// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

final class MIDIConnectionTableCell: UITableViewCell, ReusableView, NibLoadableView {
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var connected: UISwitch!

  public override func awakeFromNib() {
    super.awakeFromNib()
    connected.onTintColor = UIColor.systemTeal
  }
}
