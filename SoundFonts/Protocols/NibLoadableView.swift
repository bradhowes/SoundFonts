//
//  NibLoadableView.swift
//  SoundFonts
//
//  Created by Brad Howes on 2/13/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import UIKit

protocol NibLoadableView: class {
    static var nibName: String { get }
    static var nib: UINib { get }
}

extension NibLoadableView where Self: UIView {

    static var nibName: String { return NSStringFromClass(self).components(separatedBy: ".").last! }

    static var nib: UINib {
        let bundle = Bundle(for: self)
        return UINib(nibName: nibName, bundle: bundle)
    }
}
