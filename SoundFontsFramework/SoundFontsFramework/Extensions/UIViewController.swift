// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public extension UIViewController {

  /**
   Add the given UIViewController as a child.

   - parameter child: the UIViewController to add
   */
  func add(_ child: UIViewController) {
    addChild(child)
    view.addSubview(child.view)
    child.didMove(toParent: self)
  }
}
