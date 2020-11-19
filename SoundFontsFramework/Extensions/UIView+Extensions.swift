// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public extension UIView {

    @IBInspectable var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth =  newValue }
    }

    @IBInspectable var borderColor: UIColor? {
        get { layer.borderColor != nil ? UIColor(cgColor: layer.borderColor!) : nil }
        set { layer.borderColor =  newValue?.cgColor }
    }
}

public extension UILabel {

    func showStatus(_ status: String, duration: Double = 1.0) {
        if let statusTimer = (objc_getAssociatedObject(self, "statusTimer") as? Timer) {
            statusTimer.invalidate()
        }

        let originalText = (objc_getAssociatedObject(self, "originalText") as? String) ?? self.text
        objc_setAssociatedObject(self, "originalText", originalText, .OBJC_ASSOCIATION_RETAIN)
        let statusTimer = Timer.once(after: duration) { _ in
            self.fadeTransition(0.4)
            self.text = originalText
        }

        self.layer.removeAllAnimations()
        objc_setAssociatedObject(self, "statusTimer", statusTimer, .OBJC_ASSOCIATION_RETAIN)
        fadeTransition(0.4)
        self.text = status
    }

    private func fadeTransition(_ duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
