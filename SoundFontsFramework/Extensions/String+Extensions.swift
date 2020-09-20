// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

private class Tag: NSObject {}

extension String {
    private static let tag = Tag()
    public var systemFontWidth: CGFloat { (self as NSString).size(withAttributes: systemFontAttributes).width }
    public func localized(comment: String) -> String { NSLocalizedString(self, bundle: Bundle(for: Tag.self), comment: comment) }
}

extension String {

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
