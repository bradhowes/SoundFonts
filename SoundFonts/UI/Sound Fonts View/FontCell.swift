// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
final class FontCell: FontPatchCellBase, ReusableView, NibLoadableView {
    private lazy var log = Logging.logger("FontCell")

    /**
     Configure the cell to show SoundFont info
    
     - parameter name: the name to show
     - parameter isActive: true if the SoundFont has the patch that is currently active
     */
    func update(name: String, isSelected: Bool, isActive: Bool) {
        os_log(.debug, log: log, "update '%s' isSelected: %d isActive: %d", name, isSelected, isActive)
        self.name.text = name
        self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: false)
    }
}
