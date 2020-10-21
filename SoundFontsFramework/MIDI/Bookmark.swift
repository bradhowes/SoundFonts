// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

public final class Bookmark: Codable {
    private static let log = Logging.logger("Bookmark")
    static let resourceKeys = Set<URLResourceKey>(arrayLiteral: .fileSizeKey, .isUbiquitousItemKey, .canonicalPathKey)

    private var log: OSLog { Self.log }

    private var url: URL
    private var bookmark: Data?

    public init(url: URL) {
        self.url = url
        updateBookmark(url: url)
        os_log(.info, log: log, "url: %{public}s data.count: %d", url.path, bookmark?.count ?? 0)
    }
}

extension Bookmark {

    var fileURL: URL {
        os_log(.info, log: log, "generating fileURL")
        guard let data = self.bookmark else {
            os_log(.error, log: log, "no bookmark data")
            return self.url
        }

        do {
            os_log(.info, log: log, "attempting to resolve bookmark")
            var isStale = false
            let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            os_log(.info, log: log, "resolved bookmark to '%{public}s' isStale: %d", url.path, isStale)
            if isStale {
                os_log(.info, log: log, "updating bookmark")
                updateBookmark(url: url)
            }
            return url
        }
        catch {
            os_log(.error, log: log, "failed to resolve bookmark - %{public}s", error.localizedDescription)
            return self.url
        }
    }
}

extension Bookmark {

    private func updateBookmark(url: URL) {
        os_log(.info, log: log, "updateBookmark")
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        do {
            self.bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: Self.resourceKeys, relativeTo: nil)
            self.url = url
        } catch {
            os_log(.error, log: log, "failed to generate bookmark for '%{public}s' - %{public}s", url.path, error.localizedDescription)
        }
    }
}

extension Bookmark: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(url) }
    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool { lhs.url == rhs.url }
}
