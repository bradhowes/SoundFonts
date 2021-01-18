// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public enum TagsEvent {

    case added(new: Int, tag: LegacyTag)
    case moved(old: Int, new: Int, tag: LegacyTag)
    case removed(old: Int, tag: LegacyTag)
    case restored
}

public protocol Tags: class {

    var restored: Bool { get }

    var isEmpty: Bool { get }

    var count: Int { get }

    func names(of keys: [LegacyTag.Key]) -> [String]

    func index(of: LegacyTag.Key) -> Int?

    func getBy(index: Int) -> LegacyTag

    func getBy(key: LegacyTag.Key) -> LegacyTag?

    func add(tag: LegacyTag) -> Int

    func remove(index: Int) -> LegacyTag

    func rename(index: Int, name: String)

    func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (TagsEvent) -> Void) -> SubscriberToken
}
