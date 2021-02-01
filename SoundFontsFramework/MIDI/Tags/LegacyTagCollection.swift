// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os

public final class LegacyTagCollection: Codable {

    private var log: OSLog { Logging.logger("TagCol") }

    private var tags: [LegacyTag]

    public var isEmpty: Bool { return tags.isEmpty }

    public var count: Int { tags.count }

    public init(tags: [LegacyTag] = []) { self.tags = tags }

    public func names(of keys: Set<LegacyTag.Key>) -> [String] { keys.compactMap { getBy(key: $0)?.name } }

    public func index(of key: LegacyTag.Key) -> Int? { tags.firstIndex { $0.key == key } }

    public func getBy(index: Int) -> LegacyTag { tags[index] }

    public func getBy(key: LegacyTag.Key) -> LegacyTag? { tags.first { $0.key == key } }

    public func append(_ tag: LegacyTag) -> Int {
        tags.append(tag)
        return count - 1
    }

    public func insert(_ tag: LegacyTag, at index: Int) { tags.insert(tag, at: index) }

    public func remove(at index: Int) -> LegacyTag { tags.remove(at: index) }

    public func rename(_ index: Int, name: String) { tags[index].name = name }
}

extension LegacyTagCollection: CustomStringConvertible {
    public var description: String { tags.description }
}

extension LegacyTagCollection {
    public func cleanup() {
        tags.removeAll { $0.name == "All" }
    }
}
