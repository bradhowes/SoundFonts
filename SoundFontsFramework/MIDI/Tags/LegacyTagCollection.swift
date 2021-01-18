// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public final class LegacyTagCollection: Codable {

    enum CodingKeys: String, CodingKey {
        case tags
    }

    private var tags: [LegacyTag]

    public var markDirty: (() -> Void)!
    public var isEmpty: Bool { return tags.isEmpty }
    public var count: Int { tags.count }

    public init(tags: [LegacyTag], markDirty: @escaping () -> Void) {
        self.tags = tags
        self.markDirty = markDirty
    }

    public func index(of key: LegacyTag.Key) -> Int? { tags.firstIndex { $0.key == key } }

    public func getBy(index: Int) -> LegacyTag { tags[index] }

    public func getBy(key: LegacySoundFont.Key) -> LegacyTag? { tags.first { $0.key == key } }

    public func add(_ tag: LegacyTag) -> Int {
        defer { collectionChanged() }
        tags.append(tag)
        return count - 1
    }

    public func remove(_ index: Int) -> LegacyTag {
        defer { collectionChanged() }
        return tags.remove(at: index)
    }

    public func rename(_ index: Int, name: String) {
        defer { collectionChanged() }
        tags[index].name = name
    }
}

extension LegacyTagCollection: CustomStringConvertible {
    public var description: String { tags.description }
}

extension LegacyTagCollection {
    private func collectionChanged() {
        markDirty()
        AskForReview.maybe()
    }
}
