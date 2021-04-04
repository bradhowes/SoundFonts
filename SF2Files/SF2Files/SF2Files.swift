// Copyright © 2020 Brad Howes. All rights reserved.

private final class SF2FilesTag {}

@objc @objcMembers public class SF2Files: NSObject {

    @objc public static let sf2Extension = "sf2"
    @objc public static let sf2DottedExtension = "." + sf2Extension

    private static let bundle = Bundle(for: SF2FilesTag.self)

    /**
     Locate a specific SF2 resource by name.

     - parameter name: the name to look for
     - returns: the URL of the resource in the bundle
     */
    @objc public class func resource(name: String) -> URL {
        guard let url = bundle.url(forResource: name, withExtension: sf2Extension) else {
            fatalError("missing SF2 resource \(name)")
        }
        return url
    }

    private static let allResourcesCount = 4;

    /// Obtain collection of all of the SF2 resources in the bundle.
    @objc public class var allResources: [URL] {
        guard let urls = bundle.urls(forResourcesWithExtension: sf2Extension, subdirectory: nil),
              urls.count == allResourcesCount else {
            fatalError("missing SF2 resources")
        }
        return urls
    }
}
