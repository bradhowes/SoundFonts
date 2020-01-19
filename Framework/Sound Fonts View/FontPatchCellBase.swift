// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public class FontPatchCellBase: UITableViewCell {

    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "✮"

    public static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    @IBOutlet internal weak var name: UILabel!

    @IBInspectable public var selectedBackgroundColor: UIColor = .darkGray {
        didSet {
            configureSelectedBackgroundViewColor()
        }
    }

    private var normalFontColor: UIColor?

    @IBInspectable public var selectedFontColor: UIColor = .white
    @IBInspectable public var activedFontColor: UIColor = .green
    @IBInspectable public var favoriteFontColor: UIColor = .yellow

    public override func awakeFromNib() {
        super.awakeFromNib()
        normalFontColor = self.name?.textColor
    }

    public func configureSelectedBackgroundViewColor() {
        let view = UIView()
        view.backgroundColor = selectedBackgroundColor
        selectedBackgroundView = view
    }

    internal func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool) -> UIColor? {
        if isActive { return activedFontColor }
        if isSelected { return selectedFontColor }
        if isFavorite { return favoriteFontColor }
        return normalFontColor
    }
}
