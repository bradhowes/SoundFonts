// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Protocol for UIView classes that can load themselves from a NIB file. To do so they must define the name of the NIB
 to be loaded and a way to obtain the UINib object where it resides.
 */
public protocol NibLoadableView: AnyObject {

    /// Obtain the name of the NIB to load
    static var nibName: String { get }

    /// Obtain the NIB that holds the view definition
    static var nib: UINib { get }
}

public extension NibLoadableView where Self: UIView {

    /// Default implementation where the NIB name is the name of the class name
    static var nibName: String { NSStringFromClass(self).components(separatedBy: ".").last! }

    /// Default implementation where the UINib is found in  the same bundle as this protocol
    static var nib: UINib { UINib(nibName: nibName, bundle: Bundle(for: self)) }
}
