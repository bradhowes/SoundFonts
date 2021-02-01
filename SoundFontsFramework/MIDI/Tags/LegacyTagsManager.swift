// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os
import SoundFontInfoLib

final class LegacyTagsManager: SubscriptionManager<TagsEvent> {
    private let log = Logging.logger("TagsMgr")

    private let configFile: ConsolidatedConfigFile

    var collection: LegacyTagCollection {
        precondition(configFile.restored)
        return configFile.config.tags
    }

    private(set) var restored = false {
        didSet { os_log(.debug, log: log, "restored: %{public}@", collection.description) }
    }

    private var configFileObserver: NSKeyValueObservation?

    init(_ consolidatedConfigFile: ConsolidatedConfigFile) {
        self.configFile = consolidatedConfigFile
        super.init()
        configFileObserver = consolidatedConfigFile.observe(\.restored) { _, _ in
            self.checkCollectionRestored()
        }
        self.checkCollectionRestored()
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
        AskForReview.maybe()
        configFile.updateChangeCount(.done)
    }

    private func checkCollectionRestored() {
        guard configFile.restored == true else { return }
        self.restored = true
        os_log(.info, log: self.log, "restored")
        DispatchQueue.main.async { self.notify(.restored) }
    }
}
