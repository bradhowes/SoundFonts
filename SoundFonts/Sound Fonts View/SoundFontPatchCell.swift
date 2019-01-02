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
final class SoundFontPatchCell: UITableViewCell {

    /// Unicode character to show when a cell refers to the active Patch
    private static let circleStarPrefix = "✪"
    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "⭐"

    static func activeTag(_ isActive: Bool) -> String { return isActive ? circleStarPrefix + " " : "" }

    static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    @IBOutlet private weak var name: UILabel!
    @IBOutlet private weak var detail: UILabel!
    
    @IBInspectable var selectionColor: UIColor = .gray {
        didSet {
            configureSelectedBackgroundViewColor()
        }
    }
    
    func configureSelectedBackgroundViewColor() {
        let view = UIView()
        view.backgroundColor = selectionColor
        selectedBackgroundView = view
    }

    /**
     Configure the cell to show SoundFont info
    
     - parameter name: the name to show
     - parameter isActive: true if the SoundFont has the patch that is currently active
     */
    func update(name: String, isActive: Bool) {
        self.name.text = SoundFontPatchCell.activeTag(isActive) + name
    }

    /**
     Configure the cell to show Patch info
    
     - parameter name: the name to show
     - parameter index: the index of the Patch in the SoundFont
     - parameter isActive: true if the Patch is currently active
     - parameter isFavorite: true if the Patch is part of a Favorite
     */
    func update(name: String, index: Int, isActive: Bool, isFavorite: Bool) {
        self.name.text = SoundFontPatchCell.activeTag(isActive) + SoundFontPatchCell.favoriteTag(isFavorite) + name
        self.detail.text = "\(index)"
    }
}
