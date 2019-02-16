//
//  UIColor+Extensions.swift
//  SoundFonts
//
//  Created by Brad Howes on 2/16/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import UIKit

extension UIColor{

    convenience init(rgb: UInt32, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgb & 0x0000FF) / 255.0,
                  alpha: alpha)
    }

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexInt: UInt32 = 0
        let scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        scanner.scanHexInt32(&hexInt)
        self.init(rgb: hexInt, alpha: alpha)
    }
}
