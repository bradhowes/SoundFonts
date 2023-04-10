// Copyright © 2023 Brad Howes. All rights reserved.

import UIKit
import CoreMIDI
import MorkAndMIDI

final class MIDIActionsTableCell: UITableViewCell, ReusableView, NibLoadableView {
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var controller: UILabel!
  @IBOutlet weak var learn: UIButton!
}
