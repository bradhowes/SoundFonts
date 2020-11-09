// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

public final class Bookmark: Codable {
    private static let log = Logging.logger("Bookmark")
    private var log: OSLog { Self.log }

    public let name: String
    private var bookmark: Data?
    private let original: URL
    private var _resolved: URL?

    enum CodingKeys: String, CodingKey {
        case name
        case bookmark
        case original
    }

    public var url: URL { _resolved ?? self.resolve() }

    public var isAvailable: Bool {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        return (try? url.checkResourceIsReachable()) ?? false
        // return (try? Data(contentsOf: url, options: .mappedIfSafe)) != nil
    }

    public var isUbiquitous: Bool {
        return FileManager.default.isUbiquitousItem(at: url)
    }

    public enum CloudState {
        case inCloud
        case downloadRequested
        case downloading
        case downloaded
        case downloadError
        case unknown
    }

    public var cloudState: CloudState {
        guard let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .ubiquitousItemDownloadingErrorKey]) else {
            return .unknown
        }
        guard values.ubiquitousItemDownloadingError == nil else { return .downloadError }
        guard let status = values.ubiquitousItemDownloadingStatus else { return .unknown }
        switch status {
        case .current: return .downloaded
        case .downloaded: return .downloading
        case .notDownloaded: return .inCloud
        default: return .unknown
        }
    }

    public init(url: URL, name: String) {
        self.name = name
        self.original = url
        let secured = url.startAccessingSecurityScopedResource()
        self.bookmark = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        if secured { url.stopAccessingSecurityScopedResource() }
        os_log(.info, log: log, "name: %{public}s data.count: %d url: %{public}s", name, bookmark?.count ?? 0, url.path)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decode(String.self, forKey: .name)
        self.original = try values.decode(URL.self, forKey: .original)
        let data = try? values.decode(Data.self, forKey: .bookmark)
        self.bookmark = data
        self._resolved = Self.resolve(from: data)
    }

    private static func resolve(from data: Data?) -> URL? {
        guard let data = data else { return nil }
        var isStale = false
        return try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
    }

    private func resolve() -> URL {
        if let url = _resolved { return url }
        _resolved = Self.resolve(from: self.bookmark)
        return _resolved ?? original
    }

    private func dumpDetails() {
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .isUbiquitousItemKey, .canonicalPathKey, .volumeNameKey])
        os_log(.debug, log: log, "-- details of %{public}s", url.path)
        os_log(.debug, log: log, "fileSize: %d", resourceValues?.fileSize ?? -1)
        os_log(.debug, log: log, "isUbiquitousItem: %{public}s", resourceValues?.isUbiquitousItem?.description ?? "?")
        os_log(.debug, log: log, "canonicalPath: %{public}s", resourceValues?.canonicalPath ?? "?")
        os_log(.debug, log: log, "volumeName: %{public}s", resourceValues?.volumeName ?? "?")
    }
}

extension Bookmark: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bookmark)
    }

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool { lhs.bookmark == rhs.bookmark }
}
