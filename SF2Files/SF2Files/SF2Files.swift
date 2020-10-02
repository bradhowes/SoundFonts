// Created by Brad Howes on 9/26/20.

private final class SF2FilesTag {}

public enum SF2Files {}

extension SF2Files {
    public static let sf2Extension = "sf2"
    public static let sf2DottedExtension = "." + sf2Extension
    private static let bundle = Bundle(for: SF2FilesTag.self)

    /**
     Locate a specific SF2 resource by name.

     - parameter name: the name to look for
     - returns: the URL of the resource in the bundle
     */
    public static func resource(name: String) -> URL {
        guard let url = bundle.url(forResource: name, withExtension: sf2Extension) else { fatalError("missing SF2 resource \(name)") }
        return url
    }
}

extension SF2Files {
    private static let allResourcesCount = 4;

    /// Obtain collection of all of the SF2 resources in the bundle.
    public static var allResources: [URL] {
        guard let urls = bundle.urls(forResourcesWithExtension: sf2Extension, subdirectory: nil),
              urls.count == allResourcesCount else {
            fatalError("missing SF2 resources")
        }
        return urls
    }
}
