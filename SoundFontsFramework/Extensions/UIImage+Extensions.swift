// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

private class ThisBundleTag: NSObject {}

public extension UIImage {

    static func resourceImage(name: String) -> UIImage? { UIImage(named: name, in: Bundle(for: ThisBundleTag.self), compatibleWith: .none) }
}
