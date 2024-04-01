// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Specialization of `UICollectionViewCell` that knows how to render Favorite names.
final class FavoriteCell: UICollectionViewCell, ReusableView, NibLoadableView {
  private lazy var log = Logging.logger("FavoriteCell")

  /// The name of the favorite
  @IBOutlet private weak var name: UILabel!

  /// Hack to properly manage the items width. Starts out disabled, but will be enabled when maxWidth is set.
  @IBOutlet private weak var maxWidthConstraint: NSLayoutConstraint? {
    didSet {
      maxWidthConstraint?.isActive = false
    }
  }

  /// The background color of an inactive favorite cell
  let normalBackgroundColor = UIColor(hex: "141414")

  /// Foreground color of an inactive favorite cell
  var normalForegroundColor = UIColor.lightGray

  /// Background color of the active favorite cell
  var activeBackgroundColor = UIColor(hex: "141414")

  /// Foreground color of the active favorite cell
  var activeForegroundColor = UIColor.systemTeal

  /// Foreground color of the active favorite cell
  var pendingForegroundColor = UIColor.systemTeal.darker(0.7)

  let normalBorderColor = UIColor.darkGray

  /// Attribute set by the FavoritesViewController to limit the cell's width
  var maxWidth: CGFloat? {
    didSet {
      guard let maxWidth = maxWidth else { return }
      maxWidthConstraint?.isActive = true
      maxWidthConstraint?.constant = maxWidth
    }
  }

  /// Indicates if the cell is currently moving around. Update the border color when it is.
  var moving: Bool = false {
    didSet { self.layer.borderColor = (moving ? UIColor.systemOrange : normalBorderColor).cgColor }
  }

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
   - parameter loading: true if the preset is loading.
   */
  func update(favoriteName: String, isActive: Bool) {
    os_log(.debug, log: log, "update: %{public}s %d %d", favoriteName, isActive)

    name.text = favoriteName
    if isActive {
      let foregroundColor = activeForegroundColor
      backgroundColor = activeBackgroundColor
      name.textColor = foregroundColor
      layer.borderColor = foregroundColor.cgColor
    } else {
      backgroundColor = normalBackgroundColor
      name.textColor = normalForegroundColor
      layer.borderColor = UIColor.darkGray.cgColor
    }

    self.name.accessibilityLabel = "favorite \(favoriteName)"
    self.name.accessibilityHint = "favorite collection entry for favorite \(favoriteName)"

    invalidateIntrinsicContentSize()
  }

  /// Report the layout size for a given target size. Forward request to the content view.
  override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
    contentView.systemLayoutSizeFitting(targetSize)
  }
}

extension FavoriteCell {

  fileprivate func setupView() {
    layer.borderColor = UIColor.darkGray.cgColor
    layer.borderWidth = 1.0
    layer.cornerRadius = 10.0

    contentView.translatesAutoresizingMaskIntoConstraints = false
    invalidateIntrinsicContentSize()
  }
}
