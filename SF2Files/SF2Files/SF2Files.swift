// Created by Brad Howes on 9/26/20.

public final class SF2FilesTag {}

public enum SF2Files {}

extension SF2Files {
    public static let sf2Extension = "sf2"
    public static let sf2DottedExtension = "." + sf2Extension

    private static let bundle = Bundle(for: SF2FilesTag.self)

    public static func resource(name: String) -> URL {
        guard let url = bundle.url(forResource: name, withExtension: sf2Extension) else { fatalError("missing SF2 resource \(name)") }
        return url
    }
}

extension SF2Files {

    public static var allResources: [URL] {
        guard let urls = bundle.urls(forResourcesWithExtension: sf2Extension, subdirectory: nil), !urls.isEmpty else { fatalError("missing SF2 resources") }
        return urls
    }
}


