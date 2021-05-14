// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

private class BundleTag: NSObject {}

extension String {

    /**
     Obtain the width of the string if rendered in the system font
     */
    public var systemFontWidth: CGFloat { (self as NSString).size(withAttributes: systemFontAttributes).width }

//    public func localized(comment: String) -> String {
//        NSLocalizedString(self, bundle: Bundle(for: BundleTag.self), comment: comment)
//    }
}

extension String {

    /**
     Remove any embedded UUID value from the string.

     - returns: named tuple with the stripped result and an option UUID value
     */
    public func stripEmbeddedUUID() -> (stripped: String, uuid: UUID?) {
        let pattern = "[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}"
        let target = self as NSString
        let match = target.range(of: pattern, options: .regularExpression)
        guard match.location != NSNotFound else { return (stripped:self, uuid: nil) }
        let found = target.substring(with: match)
        let stripped = target.substring(to: match.location - 1) + target.substring(from: match.location + match.length)
        return (stripped: stripped, uuid: UUID(uuidString: found))
    }
}

extension String {

    /**
     Convert an object pointer into a string representation.

     - parameter object: value to convert
     - returns: string representation of the pointer
     */
    public static func pointer(_ object: AnyObject?) -> String {
        guard let object = object else { return "nil" }
        let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(object).toOpaque()
        return String(describing: opaque)
    }
}
