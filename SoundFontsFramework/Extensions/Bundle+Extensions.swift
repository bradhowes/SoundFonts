import Foundation

extension Bundle {

    private func string(forKey key: String) -> String { infoDictionary?[key] as? String ?? "" }

    var releaseVersionNumber: String { string(forKey: "CFBundleShortVersionString") }
    var buildVersionNumber: String { string(forKey: "CFBundleVersion") }
    var bundleID: String { Bundle.main.bundleIdentifier?.lowercased() ?? "" }
    var scheme: String {
        if bundleID.contains(".dev") { return " Dev" }
        if bundleID.contains(".staging") { return " Staging" }
        return ""
    }

    var versionString: String { "Version \(releaseVersionNumber).\(buildVersionNumber)\(scheme)" }
}
