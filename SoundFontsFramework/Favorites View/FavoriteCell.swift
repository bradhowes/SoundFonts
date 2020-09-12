// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of `UICollectionViewCell` that knows how to render Favorite attributes.
 */
@IBDesignable
final class FavoriteCell: UICollectionViewCell, ReusableView, NibLoadableView {
    private lazy var log = Logging.logger("FavCell")

    /// The name of the favorite
    @IBOutlet private weak var name: UILabel!

    /// Hack to properly manage the items width. Starts out disabled, but will be enabled when maxWidth is set.
    @IBOutlet private weak var maxWidthConstraint: NSLayoutConstraint! { didSet { maxWidthConstraint.isActive = false } }

    /// The background color of an inactive favorite cell
    @IBInspectable var normalBackgroundColor: UIColor! { didSet { self.backgroundColor = normalBackgroundColor } }

    /// Foreground color of an inactive favorite cell
    @IBInspectable var normalForegroundColor: UIColor!

    /// Background color of the active favorite cell
    @IBInspectable var activeBackgroundColor: UIColor!

    /// Foreground color of the active favorite cell
    @IBInspectable var activeForegroundColor: UIColor!

    private var normalBorderColor: UIColor?

    /// Attribute set by the FavoritesViewController to limit the cell's width
    var maxWidth: CGFloat? = nil {
        didSet {
            guard let maxWidth = maxWidth else { return }
            maxWidthConstraint.isActive = true
            maxWidthConstraint.constant = maxWidth
        }
    }

    /// Indicates if the cell is currently moving around. Update the border color when it is.
    var moving: Bool = false { didSet { self.borderColor = moving ? UIColor.magenta : normalBorderColor } }

    /// The intrinsic size of the cell is its content view with the current label text.
    override var intrinsicContentSize: CGSize {
        contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    /**
     Show the Favorite name and `active` indicator.
    
     - parameter favoriteName: the name to show
     - parameter isActive: true if the Favorite's patch is currently active.
     */
    func update(favoriteName: String, isActive: Bool) {
        os_log(.info, log: log, "update: %s %d", favoriteName, isActive)

        name.text = favoriteName
        if isActive {
            backgroundColor = activeBackgroundColor
            name.textColor = activeForegroundColor
            borderColor = activeForegroundColor
        }
        else {
            backgroundColor = normalBackgroundColor
            name.textColor = normalForegroundColor
            borderColor = .darkGray
        }

        invalidateIntrinsicContentSize()
    }

    /// Report the layout size for a given target size. Foward request to the content view.
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        contentView.systemLayoutSizeFitting(targetSize)
    }
}

private extension FavoriteCell {

    func setupView() {
        normalBorderColor = borderColor
        contentView.translatesAutoresizingMaskIntoConstraints = false
        invalidateIntrinsicContentSize()
    }
}
