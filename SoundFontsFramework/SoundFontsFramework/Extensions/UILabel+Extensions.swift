// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import UIKit

private var stringAssociation = AssociatedObject<String>()
private var timerAssociation = AssociatedObject<Timer>()

extension UILabel {

  private var originalText: String? {
    get {
      if let value = stringAssociation[self] { return value }
      let value = self.text ?? "?"
      stringAssociation[self] = value
      return value
    }
    set { stringAssociation[self] = newValue }
  }

  private var fadeTimer: Timer? {
    get { timerAssociation[self] }
    set { timerAssociation[self] = newValue }
  }

  /**
     Show a temporary status string in a label, replacing its current value. After some amount of time elapses, restore
     the label to the original content.

     - parameter status: the value to show
     - parameter duration: the amount of time to show the status value
     */
  public func showStatus(_ status: String, duration: Double = 1.0) {
    if let timer = self.fadeTimer {
      timer.invalidate()
    }

    let originalText = self.originalText
    fadeTimer = Timer.once(after: 1.0) { _ in
      UIView.transition(
        with: self, duration: 0.5, options: [.curveLinear, .transitionCrossDissolve]
      ) {
        self.text = originalText
      } completion: { _ in
        self.text = originalText
      }
    }
    text = status
  }

  private func fadeTransition() {
    let animation = CATransition()
    animation.type = CATransitionType.fade
    layer.add(animation, forKey: nil)
  }
}
