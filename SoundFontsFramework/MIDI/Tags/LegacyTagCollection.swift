// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os

internal final class LegacyTagCollection: Codable {
    private var log: OSLog { Logging.logger("TagCol") }

    private var tags: [LegacyTag]

    internal var isEmpty: Bool { return tags.isEmpty }

    internal var count: Int { tags.count }

    internal init(tags: [LegacyTag]) { self.tags = tags }

    internal func names(of keys: Set<LegacyTag.Key>) -> [String] { keys.compactMap { getBy(key: $0)?.name } }

    internal func index(of key: LegacyTag.Key) -> Int? { tags.firstIndex { $0.key == key } }

    internal func getBy(index: Int) -> LegacyTag { tags[index] }

    internal func getBy(key: LegacyTag.Key) -> LegacyTag? { tags.first { $0.key == key } }

    internal func append(_ tag: LegacyTag) -> Int {
        tags.append(tag)
        return count - 1
    }

    internal func insert(_ tag: LegacyTag, at index: Int) { tags.insert(tag, at: index) }

    internal func remove(at index: Int) -> LegacyTag { tags.remove(at: index) }

    internal func rename(_ index: Int, name: String) { tags[index].name = name }
}

extension LegacyTagCollection: CustomStringConvertible {
    public var description: String { tags.description }
}

extension LegacyTagCollection {
    internal func cleanup() {
        tags.removeAll { $0.name == "All" }
    }
}