import Foundation
import UIKit

private class BundleTag: NSObject {}

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

public protocol AppExtensionBundleInfo {

  var bundleID: String { get }

  var auExtensionUrl: URL? { get }

  func info(for key: String) -> String
}

public extension AppExtensionBundleInfo {

  var scheme: String {
    if bundleID.contains(".dev") { return " Dev" }
    if bundleID.contains(".staging") { return " Staging" }
    return ""
  }

  /// Obtain the release version number associated with the bundle or "" if none found
  var releaseVersionNumber: String { info(for: "CFBundleShortVersionString") }

  /// Obtain a well-formed version tag that starts with a "v" before the `releaseVersionNumber`
  var versionTag: String {
    let version = releaseVersionNumber
    return version.first == "v" ? version : "v" + version
  }

  /// Obtain the build version number associated with the bundle or "" if none found
  var buildVersionNumber: String { info(for: "CFBundleVersion") }

  /// Obtain a version string with the following format: "Version V.B[ S]"
  /// where V is the releaseVersionNumber, B is the buildVersionNumber and S is the scheme.
  var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(scheme)" }

  // NOTE: for the following values to have meaningful values, one must define them in an Info.plist file for the
  // bundle where this file resides.

  /// Obtain the base name of the audio unit
  var auBaseName: String { info(for: "AU_BASE_NAME") }
  /// Obtain the component name of the audio unit
  var auComponentName: String { info(for: "AU_COMPONENT_NAME") }
  /// Obtain the type of the audio unit as a string
  var auComponentTypeString: String { info(for: "AU_COMPONENT_TYPE") }
  /// Obtain the subtype of the audio unit as a string
  var auComponentSubtypeString: String { info(for: "AU_COMPONENT_SUBTYPE") }
  /// Obtain the manufacturer of the audio unit as a string
  var auComponentManufacturerString: String { info(for: "AU_COMPONENT_MANUFACTURER") }
  /// Obtain the type of the audio unit
  var auComponentType: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_TYPE")) }
  /// Obtain the subtype of the audio unit
  var auComponentSubtype: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_SUBTYPE")) }
  /// Obtain the manufacturer of the audio unit
  var auComponentManufacturer: FourCharCode { FourCharCode(stringLiteral: info(for: "AU_COMPONENT_MANUFACTURER")) }
  /// Obtain the extension name
  var auExtensionName: String { auBaseName + "AU.appex" }
  /// Obtain the Apple Store ID for the component
  var appStoreId: String { info(for: "APP_STORE_ID") }
}

extension Bundle: AppExtensionBundleInfo {

  public var bundleID: String { self.bundleIdentifier?.lowercased() ?? "" }

  public var auExtensionUrl: URL? {
    builtInPlugInsURL?.appendingPathComponent(auExtensionName)
  }

  @inlinable
  public func info(for key: String) -> String { infoDictionary?[key] as? String ?? "" }
}
