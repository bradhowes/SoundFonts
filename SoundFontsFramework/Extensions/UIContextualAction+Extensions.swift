// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public extension UIContextualAction {

    /**
     Convenience constructor. The given tag is used to obtain the UIImage to use in the action representation.

     - parameter tag: the name of the action
     - parameter color: the background color of the action
     - parameter handler: the closure to invoke when the action fires
     */
    convenience init(tag: String, color: UIColor, handler: @escaping Handler) {
        self.init(style: .normal, title: nil, handler: handler)
        self.image = UIImage.resourceImage(name: tag)
        self.backgroundColor = color
        self.accessibilityLabel = tag + "SwipeAction"
        self.accessibilityHint = tag + "SwipeAction"
        self.isAccessibilityElement = true
    }
}
