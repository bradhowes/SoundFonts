// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of `UICollectionViewCell` that knows how to render Favorite attributes.
 */
@IBDesignable
final class FavoriteCell: UICollectionViewCell, ReusableView, NibLoadableView {
    private lazy var logger = Logging.logger("FavC")

    /// The name of the favorite
    @IBOutlet weak var name: UILabel!

    /// The background color of an inactive favorite cell
    @IBInspectable var normalBackgroundColor: UIColor! {
        didSet {
            self.backgroundColor = normalBackgroundColor
        }
    }

    /// Foreground color of an inactive favorite cell
    @IBInspectable var normalForegroundColor: UIColor!

    /// Background color of the active favorite cell
    @IBInspectable var activeBackgroundColor: UIColor!

    /// Foreground color of the active favorite cell
    @IBInspectable var activeForegroundColor: UIColor!

    private var normalBorderColor: UIColor?

    @IBOutlet private var maxWidthConstraint: NSLayoutConstraint! {
        didSet {
            maxWidthConstraint.isActive = false
        }
    }

    var maxWidth: CGFloat? = nil {
        didSet {
            guard let maxWidth = maxWidth else {
                return
            }
            maxWidthConstraint.isActive = true
            maxWidthConstraint.constant = maxWidth
        }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    /// Indicates if the cell is currently moving around. Update the border color when it is.
    public var moving: Bool = false {
        didSet {
            if moving {
                self.borderColor = UIColor.magenta
            }
            else {
                self.borderColor = normalBorderColor
            }
        }
    }

    /**
     Show the Favorite name and `active` indicator.
    
     - parameter name: the name to show
     - parameter isActive: true if the Favorite's patch is currently active.
     */
    func update(name: String, isActive: Bool) {
        os_log(.info, log: logger, "update: %s %d", name, isActive)

        self.name.text = name
        if isActive {
            self.backgroundColor = activeBackgroundColor
            self.name.textColor = activeForegroundColor
        }
        else {
            self.backgroundColor = normalBackgroundColor
            self.name.textColor = normalForegroundColor
        }
        
        invalidateIntrinsicContentSize()
    }

    /// The intrinsic size of the cell is that of its content view with the current label text.
    override var intrinsicContentSize: CGSize {
        return contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    /// Report the layout size for a given target size. Foward request to the content view.
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return contentView.systemLayoutSizeFitting(targetSize)
    }

    private func setupView() {
        name.text = "Hello!"
        normalBorderColor = borderColor
        contentView.translatesAutoresizingMaskIntoConstraints = false
        invalidateIntrinsicContentSize()
    }
}
