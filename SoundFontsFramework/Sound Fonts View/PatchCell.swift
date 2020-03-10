// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Specialization of UITableViewCell that will display a SoundFont entry or a Patch entry.
 */
public final class PatchCell: FontPatchCellBase, ReusableView, NibLoadableView {
    private lazy var log = Logging.logger("PatchCell")

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var selectedIindicator: UIView!

    override public func prepareForReuse() {
        selectedIindicator.alpha = 0.0
    }

    override public func setSelected(_ selected: Bool, animated: Bool) {
        os_log(.info, log: log, "setSelected '%s' selected: %d animated: %d", name.text ?? "", selected, animated)
        super.setSelected(selected, animated: animated)
        let alpha: CGFloat = selected ? 1.0 : 0.0
        if animated {
            selectedIindicator.alpha = selected ? 0.0 : 1.0
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.4,
                delay: 0.0,
                options: [.allowUserInteraction, .curveEaseIn],
                animations: { self.selectedIindicator.alpha = alpha }) { _ in
                    self.selectedIindicator.alpha = alpha
            }
        }
        else {
            selectedIindicator.alpha = alpha
        }
    }

    /**
     Configure the cell to show Patch info
    
     - parameter name: the name to show
     - parameter isActive: true if the Patch is currently active
     - parameter isFavorite: true if the Patch is part of a Favorite
     */
    public func update(name: String, isSelected: Bool, isActive: Bool, isFavorite: Bool) {
        os_log(.debug, log: log, "update '%s' isActive: %d isFavorite: %d", name, isActive, isFavorite)
        self.name.text = Self.favoriteTag(isFavorite) + name
        self.name.textColor = fontColorWhen(isSelected: isSelected, isActive: isActive, isFavorite: isFavorite)
    }
}
