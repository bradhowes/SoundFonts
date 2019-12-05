// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

extension String {

    /// Obtain the width of a string in the system font
    var systemFontWidth: CGFloat { (self as NSString).size(withAttributes: systemFontAttributes).width }
}
