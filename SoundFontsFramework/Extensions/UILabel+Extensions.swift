// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit
import Foundation

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

    public func showStatus(_ status: String, duration: Double = 1.0) {
        if let timer = self.fadeTimer {
            timer.invalidate()
        }

        let originalText = self.originalText

        let timer = Timer.once(after: 1.0) { _ in
            self.layer.removeAllAnimations()
            self.fadeTransition(0.5)
            self.text = originalText
        }

        fadeTimer = timer
        text = status
    }

    private func fadeTransition(_ duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
