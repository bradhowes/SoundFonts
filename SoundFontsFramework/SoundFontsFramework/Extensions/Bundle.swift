import Foundation
import UIKit

private class BundleTag: NSObject {}

extension Bundle {

  @inlinable
  func string(forKey key: String) -> String { infoDictionary?[key] as? String ?? "" }

  /// Obtain the release version number from the bundle info
  var releaseVersionNumber: String { string(forKey: "CFBundleShortVersionString") }

  /// Obtain the build version number from the bundle info
  var buildVersionNumber: String { string(forKey: "CFBundleVersion") }

  /// Obtain a version string from the bundle info
  var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)" }
}

extension Bundle {

  /**
   Obtain a UIImage to use for an effect on/off button.

   - parameter enabled: the state of the button
   - parameter compatibleWith: traits to consider when looking for an image
   - returns: UIImage instance for the button state
   */
  static func effectEnabledButtonImage(enabled: Bool, compatibleWith: UITraitCollection? = nil) -> UIImage {
    let name = enabled ? "EffectOn" : "EffectOff"
    guard let image = UIImage(named: name, in: Bundle(for: BundleTag.self), compatibleWith: compatibleWith) else {
      fatalError("missing image '\(name)'")
    }
    return image
  }
}
