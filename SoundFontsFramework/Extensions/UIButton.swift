// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIButton {

    public func showEnabled(_ enabled: Bool) {
        UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.setImage(Bundle.buttonImage(enabled: enabled), for: .normal)
        }, completion: nil)
    }
}
