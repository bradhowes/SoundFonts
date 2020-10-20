// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

public final class Bookmark: Encodable {
    private static let log = Logging.logger("SFKind")
    private var log: OSLog { Self.log }

    private let original: URL
    private var bookmark: Data

    init(original: URL) throws {
        self.original = original
        self.bookmark = try original.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    public var fileURL: URL {
        var isStale = false
        var url: URL?
        do {
            url = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
        } catch {
            os_log(.error, log: log, "failed to resolve bookmark data for '%{public}s' - %{public}s", original.path, error.localizedDescription)
            return original
        }

        if let url = url, isStale {
            do {
                bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            } catch {
                os_log(.error, log: log, "failed to generate new bookmark data for '%{public}s' - %{public}s", url.path, error.localizedDescription)
            }
            return url
        }

        return original
    }
}

extension Bookmark: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(original)
        hasher.combine(bookmark)
    }

    public static func == (lhs: Bookmark, rhs: Bookmark) -> Bool { lhs.original == rhs.original }
}
