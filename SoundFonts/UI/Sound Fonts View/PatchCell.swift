// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
final class PatchCell: FontPatchCellBase, ReusableView, NibLoadableView {

    @IBOutlet private weak var detail: UILabel!
    
    /**
     Configure the cell to show Patch info
    
     - parameter name: the name to show
     - parameter index: the index of the Patch in the SoundFont
     - parameter isActive: true if the Patch is currently active
     - parameter isFavorite: true if the Patch is part of a Favorite
     */
    func update(name: String, index: Int, isActive: Bool, isFavorite: Bool) {
        self.name.text = PatchCell.favoriteTag(isFavorite) + name
        self.detail.text = "\(index)"
        self.name.textColor = fontColorWhen(isSelected: false, isActive: isActive, isFavorite: isFavorite)
        self.detail.textColor = fontColorWhen(isSelected: false, isActive: isActive, isFavorite: isFavorite)
    }
}
