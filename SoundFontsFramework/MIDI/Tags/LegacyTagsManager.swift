// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os
import SoundFontInfoLib

final class LegacyTagsManager: SubscriptionManager<TagsEvent> {
    private let log = Logging.logger("TagsMgr")

    private var observer: ConfigFileObserver!
    var restored: Bool { observer.restored }

    var collection: LegacyTagCollection {
        precondition(observer.restored)
        return observer.tags
    }

    init(_ consolidatedConfigFile: ConsolidatedConfigFile) {
        super.init()
        observer = ConfigFileObserver(configFile: consolidatedConfigFile, closure: collectionRestored)
    }
}

extension LegacyTagsManager: Tags {

    var isEmpty: Bool { collection.isEmpty }

    var count: Int { collection.count }

    func names(of keys: Set<LegacyTag.Key>) -> [String] { collection.names(of: keys) }

    func index(of key: LegacyTag.Key) -> Int? { collection.index(of: key) }

    func getBy(index: Int) -> LegacyTag { collection.getBy(index: index) }

    func getBy(key: LegacyTag.Key) -> LegacyTag? { collection.getBy(key: key) }

    func append(_ tag: LegacyTag) -> Int {
        defer { collectionChanged() }
        let index = collection.append(tag)
        notify(.added(new: index, tag: tag))
        return index
    }

    func insert(_ tag: LegacyTag, at index: Int) {
        defer { collectionChanged() }
        collection.insert(tag, at: index)
        notify(.added(new: index, tag: tag))
    }

    func remove(at index: Int) -> LegacyTag {
        defer { collectionChanged() }
        let tag = collection.remove(at: index)
        notify(.removed(old: index, tag: tag))
        return tag
    }

    func rename(_ index: Int, name: String) {
        defer { collectionChanged() }
        collection.rename(index, name: name)
        notify(.changed(index: index, tag: collection.getBy(index: index)))
    }

    func keySet(of indices: Set<Int>) -> Set<LegacyTag.Key> {
        Set(indices.map { collection.getBy(index: $0).key })
    }
}

extension LegacyTagsManager {

    static var defaultCollection: LegacyTagCollection { LegacyTagCollection(tags: [LegacyTag(name: "Built-in")]) }

    private func collectionChanged() {
        os_log(.info, log: log, "collectionChanged - %{public}@", collection.description)
        observer.markChanged()
    }

    private func collectionRestored() {
        os_log(.info, log: self.log, "restored")
        DispatchQueue.main.async { self.notify(.restored) }
    }
}
