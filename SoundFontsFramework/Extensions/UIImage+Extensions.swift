// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

private class ThisBundleTag: NSObject {}

public extension UIImage {

    /**
     Obtain a resource image from this bundle with the given name.

     - parameter name: the name of the image to fetch
     - returns: found UIImage or nil
     */
    static func resourceImage(name: String) -> UIImage? {
        UIImage(named: name, in: Bundle(for: ThisBundleTag.self), compatibleWith: .none)
    }
}
