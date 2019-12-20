// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public extension UIPopoverPresentationController {

    var sourceViewXOffset: CGFloat { 32.0 }

    func setSourceView(_ view: UIView) {
        self.barButtonItem = nil
        self.sourceView = view
        let rect = view.bounds
        self.sourceRect = view.convert(CGRect(origin: rect.offsetBy(dx: rect.width - sourceViewXOffset, dy: 0).origin,
                                              size: CGSize(width: sourceViewXOffset, height: rect.height)), to: nil)
    }
}
