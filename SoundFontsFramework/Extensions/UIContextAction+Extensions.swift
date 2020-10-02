// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public extension UIContextualAction {

    convenience init(tag: String, color: UIColor, handler: @escaping UIContextualAction.Handler) {
        self.init(style: .normal, title: nil, handler: handler)
        self.image = UIImage.resourceImage(name: tag)
        self.backgroundColor = color
        self.accessibilityLabel = tag + "SwipeAction"
        self.accessibilityHint = tag + "SwipeAction"
        self.isAccessibilityElement = true
    }
}
