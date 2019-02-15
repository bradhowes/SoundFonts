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
class FontPatchCellBase: UITableViewCell {

    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "✮"
    static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    @IBOutlet internal weak var name: UILabel!

    @IBInspectable var selectedBackgroundColor: UIColor = .darkGray {
        didSet {
            configureSelectedBackgroundViewColor()
        }
    }

    private var normalFontColor: UIColor?
    @IBInspectable var selectedFontColor: UIColor = .white
    @IBInspectable var activedFontColor: UIColor = .green

    override func awakeFromNib() {
        super.awakeFromNib()
        normalFontColor = self.name?.textColor
    }

    func configureSelectedBackgroundViewColor() {
        let view = UIView()
        view.backgroundColor = selectedBackgroundColor
        selectedBackgroundView = view
    }

    internal func fontColorWhen(isSelected: Bool, isActive: Bool) -> UIColor? {
        if isActive { return activedFontColor }
        if isSelected { return selectedFontColor }
        return normalFontColor
    }
}
