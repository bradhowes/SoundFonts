// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private let systemFontAttributes = [
  NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)
]

private class BundleTag: NSObject {}

extension String {

  /**
     Obtain the width of the string if rendered in the system font
     */
  public var systemFontWidth: CGFloat {
    (self as NSString).size(withAttributes: systemFontAttributes).width
  }
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
    guard match.location != NSNotFound else { return (stripped: self, uuid: nil) }
    let found = target.substring(with: match)
    let stripped =
      target.substring(to: match.location - 1)
      + target.substring(from: match.location + match.length)
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

public struct VersionComponents: Comparable {
  let major: Int
  let minor: Int
  let patch: Int

  public static func < (lhs: VersionComponents, rhs: VersionComponents) -> Bool {
    lhs.major < rhs.major
      || (lhs.major == rhs.major
        && (lhs.minor < rhs.minor
          || (lhs.minor == rhs.minor && lhs.patch < rhs.patch)))
  }
}

extension String {

  public var versionComponents: VersionComponents {
    let values =
      self.split(separator: ".").map { Int($0.split(separator: " ")[0]) ?? 0 } + [0, 0, 0]
    return VersionComponents(major: values[0], minor: values[1], patch: values[2])
  }
}
