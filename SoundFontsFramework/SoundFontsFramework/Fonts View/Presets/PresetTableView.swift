// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit.UITableView

extension UITableViewDelegate {

  /**
   Allow delegate to modify
   */
  public func validateContentOffset(_ offset: CGPoint, for tableView: UITableView) -> CGPoint {
    return offset
  }
}

class PresetTableView: UITableView {

  open override var contentOffset: CGPoint {
    get { return super.contentOffset }
    set {
      super.contentOffset = delegate?.validateContentOffset(newValue, for: self) ?? newValue
    }
  }
}
