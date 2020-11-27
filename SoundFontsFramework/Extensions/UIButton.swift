// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIButton {

    public func showEnabled(_ enabled: Bool) {
        self.setImage(Bundle.buttonImage(enabled: enabled), for: .normal)
    }
}
