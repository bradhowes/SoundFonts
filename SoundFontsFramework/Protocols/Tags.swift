// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public enum TagsEvent {

    case added(new: Int, tag: LegacyTag)
    case moved(old: Int, new: Int, tag: LegacyTag)
    case changed(index: Int, tag: LegacyTag)
    case removed(old: Int, tag: LegacyTag)
    case restored
}

public protocol Tags: class {

    var restored: Bool { get }

    var isEmpty: Bool { get }

    var count: Int { get }

    func names(of keys: Set<LegacyTag.Key>) -> [String]

    func index(of: LegacyTag.Key) -> Int?

    func getBy(index: Int) -> LegacyTag

    func getBy(key: LegacyTag.Key) -> LegacyTag?

    func append(_ tag: LegacyTag) -> Int

    func remove(at index: Int) -> LegacyTag

    func rename(_ index: Int, name: String)

    func insert(_ tag: LegacyTag, at index: Int)

    func keySet(of indices: Set<Int>) -> Set<LegacyTag.Key>

    func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (TagsEvent) -> Void) -> SubscriberToken
}
