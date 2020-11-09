import Foundation

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
}
