// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit.UITableView

protocol ContentOffsetMonitor {
  func validate(_ offset: CGPoint) -> CGPoint
}

class PresetTableView: UITableView {

  public var contentOffsetMonitor: ContentOffsetMonitor?

  open override var contentOffset: CGPoint {
    get { return super.contentOffset }
    set {
      if let monitor = self.contentOffsetMonitor, !self.isTracking {
        super.contentOffset = monitor.validate(newValue)
      } else {
        super.contentOffset = newValue
      }
    }
  }
}
