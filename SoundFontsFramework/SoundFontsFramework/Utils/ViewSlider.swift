// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/// Instances know how to slide themselves around horizontally.
final class ViewSlider: CustomStringConvertible {

  /// The view that is being slid
  let view: UIView
  /// Custom description for instance
  var description: String { "UpperViewSlider(\(view.restorationIdentifier ?? "NA")" }
  /// The known constraints for the view
  let constraints: [NSLayoutConstraint]

  /**
   Create a new slider for the given view.

   - parameter view: the view to slide
   */
  init(view: UIView) {
    guard let allConstraints = view.superview?.constraints else {
      preconditionFailure("missing constraints in superview")
    }

    self.view = view
    self.constraints =
      allConstraints
      .filter {
        $0.firstItem === view && ($0.firstAttribute == .leading || $0.firstAttribute == .trailing)
      }
    precondition(self.constraints.count == 2, "missing one or more constraints")
  }

  /**
   Slide the view to the left.
   */
  func slideLeft() {
    slide(offset: view.frame.size.width)
  }

  /**
   Slide the view to the right.
   */
  func slideRight() {
    slide(offset: -view.frame.size.width)
  }
}

extension ViewSlider {

  /**
   Slide the view in the direction managed by the given constraints. Uses CoreAnimation to show the
   view sliding in/out

   - parameter state: indicates if the view is sliding into view (true) or sliding out of view (false)
   - parameter a: the constraint for left or top
   - parameter b: the constraint for right or bottom
   - parameter constant: the value that will be used to animate over
   */
  private func slide(offset: CGFloat) {
    let slidingIn = view.isHidden

    if slidingIn {
      constraints.forEach { $0.constant = offset }
      view.superview?.layoutIfNeeded()
      self.view.isHidden = false
    }

    let goal = slidingIn ? 0 : -offset

    UIView.animate(
      withDuration: 0.25,
      animations: {
        self.constraints.forEach { $0.constant = goal }
        self.view.superview?.layoutIfNeeded()
      },
      completion: { _ in
        self.view.isHidden = !slidingIn
        self.view.superview?.layoutIfNeeded()
      })
  }
}
