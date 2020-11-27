import UIKit
import Foundation

private class Tag: NSObject {}

extension Bundle {

    public var bundleID: String { self.bundleIdentifier?.lowercased() ?? "" }

    public var scheme: String {
        if bundleID.contains(".dev") { return " Dev" }
        if bundleID.contains(".staging") { return " Staging" }
        return ""
    }

    private func string(forKey key: String) -> String { infoDictionary?[key] as? String ?? "" }

    public var releaseVersionNumber: String { string(forKey: "CFBundleShortVersionString") }
    public var buildVersionNumber: String { string(forKey: "CFBundleVersion") }
    public var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(scheme)" }

    public static func buttonImage(enabled: Bool, compatibleWith: UITraitCollection? = nil) -> UIImage {
        let name = enabled ? "EffectOn" : "EffectOff"
        guard let image = UIImage(named: name, in: Bundle(for: Tag.self), compatibleWith: compatibleWith) else { fatalError("missing image '\(name)'")}
        return image
    }
}
