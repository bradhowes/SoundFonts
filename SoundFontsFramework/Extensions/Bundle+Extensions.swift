import UIKit
import Foundation

private class BundleTag: NSObject {}

public enum BuildScheme {
    case dev
    case staging
    case release

    var tag: String {
        switch self {
        case .dev: return " Dev"
        case .staging: return " Staging"
        case .release: return ""
        }
    }
}

extension Bundle {

    /// Obtain the bundle's identifier in all lowercase characters
    public var bundleID: String { self.bundleIdentifier?.lowercased() ?? "" }

    /// Obtain a BuildScheme for this bundle
    public var scheme: BuildScheme {
        if bundleID.contains(".dev") { return .dev }
        if bundleID.contains(".staging") { return .staging }
        return .release
    }

    private func string(forKey key: String) -> String { infoDictionary?[key] as? String ?? "" }

    /// Obtain the release version number from the bundle info
    public var releaseVersionNumber: String { string(forKey: "CFBundleShortVersionString") }

    /// Obtain the build version number from the bundle info
    public var buildVersionNumber: String { string(forKey: "CFBundleVersion") }

    /// Obtain a version string from the bundle info
    public var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(scheme.tag)" }
}

extension Bundle {

    /**
     Obtain a UIImage to use for an effect on/off button.

     - parameter enabled: the state of the button
     - parameter compatibleWith: traits to consider when looking for an image
     - returns: UIImage instance for the button state
     */
    public static func effectEnabledButtonImage(enabled: Bool, compatibleWith: UITraitCollection? = nil) -> UIImage {
        let name = enabled ? "EffectOn" : "EffectOff"
        guard let image = UIImage(named: name, in: Bundle(for: BundleTag.self), compatibleWith: compatibleWith) else {
            fatalError("missing image '\(name)'")
        }
        return image
    }
}
