// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

public final class Bookmark: Codable {
    private static let log = Logging.logger("Bookmark")
    private var log: OSLog { Self.log }

    enum CodingKeys: String, CodingKey {
        case name
        case bookmark
        case original
    }

    public let name: String
    private var bookmark: Data?
    private let original: URL
    private var _resolved: URL?

    public init(url: URL, name: String) {
        self.name = name
        original = url
        bookmark = bookmarkData
        os_log(.info, log: log, "name: %{public}s data.count: %d url: %{public}s", name, bookmark?.count ?? 0, url.path)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        original = try values.decode(URL.self, forKey: .original)
        let data = try? values.decode(Data.self, forKey: .bookmark)
        bookmark = data
        _resolved = Self.resolve(from: data)
    }
}

extension Bookmark {

    public var url: URL { _resolved ?? self.resolve() }

    public var isAvailable: Bool {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        return (try? url.checkResourceIsReachable()) ?? false
    }

    public var isUbiquitous: Bool { FileManager.default.isUbiquitousItem(at: url) }

    public enum CloudState {
        case inCloud
        case downloadRequested
        case downloading
        case downloaded
        case downloadError
        case unknown
    }

    public var cloudState: CloudState {
        guard let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey,
                                                             .ubiquitousItemIsDownloadingKey,
                                                             .ubiquitousItemDownloadingErrorKey]) else {
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
}

extension Bookmark {
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

    private var bookmarkData: Data? {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        return try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
    }
}

extension Bookmark: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(bookmark) }
    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool { lhs.bookmark == rhs.bookmark }
}
