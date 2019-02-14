//
//  NibLoadableView.swift
//  SoundFonts
//
//  Created by Brad Howes on 2/13/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import UIKit

/**
 Protocol for UIView classes that can load from a NIB file
 */
protocol NibLoadableView: class {
    
    /// Obtain the name of the NIB to load
    static var nibName: String { get }
    
    /// Obtain the NIB that holds the view definition
    static var nib: UINib { get }
}

extension NibLoadableView where Self: UIView {

    /// Default implementation of the nibName that uses the name of the class as the name
    /// of the NIB file.
    static var nibName: String { return NSStringFromClass(self).components(separatedBy: ".").last! }

    /// Default implementation that obtains a UINib that holds the definition of the class
    /// that implements the protocol.
    static var nib: UINib {
        let bundle = Bundle(for: self) // Safer than Bundle.main
        return UINib(nibName: nibName, bundle: bundle)
    }
}
