// Copyright © 2018 Brad Howes. All rights reserved.

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
    @IBInspectable var favoriteFontColor: UIColor = .yellow

    override func awakeFromNib() {
        super.awakeFromNib()
        normalFontColor = self.name?.textColor
    }

    func configureSelectedBackgroundViewColor() {
        let view = UIView()
        view.backgroundColor = selectedBackgroundColor
        selectedBackgroundView = view
    }

    func setActive(_ state: Bool, isFavorite: Bool) {
        self.name?.textColor = fontColorWhen(isSelected: self.isSelected, isActive: state, isFavorite: isFavorite)
    }

    internal func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool) -> UIColor? {
        if isActive { return activedFontColor }
        if isSelected { return selectedFontColor }
        if isFavorite { return favoriteFontColor }
        return normalFontColor
    }
}
