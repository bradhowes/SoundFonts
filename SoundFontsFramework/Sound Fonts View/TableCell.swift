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

    public func updateForFont(name: String, isSelected: Bool, isActive: Bool, isReference: Bool) {
        var name = name
        if isReference {
            os_log(.info, log: log, "reference font")
            name = "❖ " + name
        }
        update(name: name, isSelected: isSelected, isActive: isActive, isFavorite: false, isEditing: false)
    }

    public func updateForPatch(name: String, isActive: Bool, isFavorite: Bool, isEditing: Bool) {
        update(name: Self.favoriteTag(isFavorite) + name, isSelected: isActive, isActive: isActive, isFavorite: isFavorite, isEditing: isEditing)
    }

    private func update(name: String, isSelected: Bool, isActive: Bool, isFavorite: Bool, isEditing: Bool) {
        self.name.text = name
        self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: isFavorite)
        if isEditing {
            activeIndicator.isHidden = true
        }
        else if isActive == activeIndicator.isHidden {
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

    private func fontColorWhen(isSelected: Bool, isActive: Bool, isFavorite: Bool) -> UIColor? {
        if isActive { return activeFontColor }
        if isFavorite { return favoriteFontColor }
        if isSelected { return selectedFontColor }
        return normalFontColor
    }
}
