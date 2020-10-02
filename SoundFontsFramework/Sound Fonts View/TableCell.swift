// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public final class TableCell: UITableViewCell, ReusableView, NibLoadableView {
    private lazy var log = Logging.logger("TableCell")

    /// Unicode character to show when a cell refers to a Patch that is in a Favorite
    private static let goldStarPrefix = "✪"

    public static func favoriteTag(_ isFavorite: Bool) -> String { return isFavorite ? goldStarPrefix + " " : "" }

    private var activeIndicatorAnimator: UIViewPropertyAnimator?

    @IBInspectable public var normalFontColor: UIColor = .lightGray
    @IBInspectable public var hiddenFontColor: UIColor = (UIColor.lightGray).withAlphaComponent(0.3)
    @IBInspectable public var selectedFontColor: UIColor = .white
    @IBInspectable public var activeFontColor: UIColor = .systemTeal
    @IBInspectable public var favoriteFontColor: UIColor = .systemYellow

    @IBOutlet private weak var name: UILabel!
    @IBOutlet private weak var activeIndicator: UIView!

    override public func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = true
        selectedBackgroundView = UIView()
        multipleSelectionBackgroundView = UIView()
    }

    public func updateForFont(name: String, isSelected: Bool, isActive: Bool) {
        update(name: name, isSelected: isSelected, isActive: isActive, isFavorite: false, isVisible: true)
    }

    public func updateForPatch(name: String, isActive: Bool, isFavorite: Bool, isVisible: Bool) {
        update(name: Self.favoriteTag(isFavorite) + name, isSelected: isActive, isActive: isActive, isFavorite: isFavorite, isVisible: isVisible)
    }

    public func updateForVisibility(name: String, isFavorite: Bool, isVisible: Bool) {
        os_log(.debug, log: log, "updateForVisibility %s %d %d", name, isFavorite, isVisible)
        self.name.text = Self.favoriteTag(isFavorite) + name
        self.name.textColor = isFavorite ? favoriteFontColor : normalFontColor
        activeIndicator.isHidden = true
        isSelected = isVisible
    }

    private func update(name: String, isSelected: Bool, isActive: Bool, isFavorite: Bool, isVisible: Bool) {
        self.name.text = name
        self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: isFavorite, isVisible: isVisible)
        if isActive == activeIndicator.isHidden {
            showActiveIndicator(isActive)
        }
    }

    private func stopAnimation() {
        activeIndicatorAnimator?.stopAnimation(false)
        activeIndicatorAnimator?.finishAnimation(at: .end)
        activeIndicatorAnimator = nil
    }

    override public func prepareForReuse() {
        stopAnimation()
        super.prepareForReuse()
    }

    private func showActiveIndicator(_ isActive: Bool) {
        stopAnimation()
        guard isActive else {
            activeIndicator.isHidden = true
            return
        }

        activeIndicator.alpha = 0.0
        activeIndicator.isHidden = false
        let activeIndicatorAnimator = UIViewPropertyAnimator(duration: 0.4, curve: .easeIn) { self.activeIndicator.alpha = 1.0 }
        activeIndicatorAnimator.addCompletion { _ in self.activeIndicator.alpha = 1.0 }
        activeIndicatorAnimator.startAnimation()
        self.activeIndicatorAnimator = activeIndicatorAnimator
    }

    private func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool, isVisible: Bool) -> UIColor? {
        if isActive { return activeFontColor }
        if isFavorite { return favoriteFontColor }
        if isSelected { return selectedFontColor }
        if isVisible { return normalFontColor }
        return hiddenFontColor
    }
}
