// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

extension UIColor {

    public convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }

        assert(hexFormatted.count == 6, "Invalid hex code used.")

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }

    /**
     Make a color that is lighter than the current one by adjusting the 'brighness' component in HSB space.

     - parameter factor: how much to increase current brightness. A value of 0.5 will increase the existing value by 50%.
     - returns: new UIColor
     */
    public func lighter(_ factor: CGFloat = 0.25) -> UIColor {
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: min(brightness * factor + brightness, 1.0),
                           alpha: alpha)
        }
        return self
    }

    /**
     Make a color that is darker than the current one by adjust the 'brightness' component in HSB space.

     - parameter factor: how much to decrease current brightness. A value of 0.25 will decrease existing value by 25%.
     - returns: new UIColor
     */
    public func darker(_ factor: CGFloat = 0.25) -> UIColor {
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: max(brightness - factor * brightness, 0.0),
                           alpha: alpha)
        }
        return self
    }
}
