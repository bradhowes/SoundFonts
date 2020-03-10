// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public class FontPatchCellBase: UITableViewCell {
    private static let log = Logging.logger("FPCB")
    private var log: OSLog { Self.log }

    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "✮"

    public static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    @IBInspectable public var selectedFontColor: UIColor = .lightGray
    @IBInspectable public var activedFontColor: UIColor = .systemTeal
    @IBInspectable public var favoriteFontColor: UIColor = .systemYellow

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = true
    }
    
    internal func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool) -> UIColor? {
        if isActive { return activedFontColor }
        if isSelected { return selectedFontColor }
        if isFavorite { return favoriteFontColor }
        return .lightGray
    }
}
