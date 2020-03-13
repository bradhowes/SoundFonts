// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]


private class Tag: NSObject {}

extension String {

    private static let tag = Tag()

    /// Obtain the width of a string in the system font
    public var systemFontWidth: CGFloat { (self as NSString).size(withAttributes: systemFontAttributes).width }

    public func localized(comment: String) -> String {
        return NSLocalizedString(self, bundle: Bundle(for: Tag.self), comment: comment)
    }
}
