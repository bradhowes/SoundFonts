// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Protocol for UIView classes that can load from a NIB file
 */
public protocol NibLoadableView: AnyObject {

    /// Obtain the name of the NIB to load
    static var nibName: String { get }

    /// Obtain the NIB that holds the view definition
    static var nib: UINib { get }
}

public extension NibLoadableView where Self: UIView {
    static var nibName: String { NSStringFromClass(self).components(separatedBy: ".").last! }
    static var nib: UINib { UINib(nibName: nibName, bundle: Bundle(for: self)) }
}
