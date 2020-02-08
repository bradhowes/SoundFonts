// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public final class PatchCell: FontPatchCellBase, ReusableView, NibLoadableView {
    private lazy var log = Logging.logger("PatchCell")

    /**
     Configure the cell to show Patch info
    
     - parameter name: the name to show
     - parameter isActive: true if the Patch is currently active
     - parameter isFavorite: true if the Patch is part of a Favorite
     */
    public func update(name: String, isActive: Bool, isFavorite: Bool) {
        os_log(.debug, log: log, "update '%s' isActive: %d isFavorite: %d", name, isActive, isFavorite)
        self.name.text = PatchCell.favoriteTag(isFavorite) + name
        self.name.textColor = fontColorWhen(isSelected: false, isActive: isActive, isFavorite: isFavorite)
        self.accessibilityLabel = "Patch " + name
    }
}
