// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIButton {

  /**
   Custom UIButton rendering for an 'enabled' state using an image.

   - parameter enabled: true if the button is enabled
   */
  func showEnabled(_ enabled: Bool) {
    UIView.transition(
      with: self, duration: 0.3, options: .transitionCrossDissolve,
      animations: {
        self.setImage(Bundle.effectEnabledButtonImage(enabled: enabled), for: .normal)
      }, completion: nil)
  }
}
