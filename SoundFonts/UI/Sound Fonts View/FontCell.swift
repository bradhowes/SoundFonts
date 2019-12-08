//
//  SoundFontPatchCell.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/21/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
final class FontCell: FontPatchCellBase, ReusableView, NibLoadableView {
    
    /**
     Configure the cell to show SoundFont info
    
     - parameter name: the name to show
     - parameter isActive: true if the SoundFont has the patch that is currently active
     */
    func update(name: String, isSelected: Bool, isActive: Bool) {
        self.name.text = name
        self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: false)
    }

    func setActive(_ state: Bool) {
        super.setActive(state, isFavorite: false)
    }
}
