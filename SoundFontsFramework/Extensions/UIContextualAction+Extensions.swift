// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public extension UIContextualAction {

    /**
     Convenience constructor.

     - parameter icon: the icon of the action
     - parameter color: the background color of the action
     - parameter handler: the closure to invoke when the action fires
     */
    convenience init(icon: Icon, color: UIColor, handler: @escaping Handler) {
        self.init(style: .normal, title: nil, handler: handler)
        self.image = icon.image
        self.backgroundColor = color
        self.accessibilityLabel = icon.accessibilityLabel
        self.accessibilityHint = icon.accessibilityHint
        self.isAccessibilityElement = true
    }
}
