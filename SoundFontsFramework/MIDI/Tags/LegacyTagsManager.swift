// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib

public final class LegacyTagsManager: SubscriptionManager<TagsEvent> {
    private let log = Logging.logger("TagsMgr")

    private var configFile: TagsConfigFile?
    private var collection: LegacyTagCollection {
        didSet { os_log(.debug, log: log, "collection changed: %{public}s", collection.description) }
    }

    public private(set) var restored = false {
        didSet { os_log(.debug, log: log, "restored: %{public}@", collection.description) }
    }

    public init() {
        os_log(.info, log: log, "init")
        self.collection = Self.defaultCollection
        super.init()
        DispatchQueue.global(qos: .userInitiated).async { self.configFile = TagsConfigFile(tagsManager: self) }
    }
}

extension LegacyTagsManager: Tags {

    public var isEmpty: Bool { collection.isEmpty }

    public var count: Int { collection.count }

    public func names(of keys: Set<LegacyTag.Key>) -> [String] { collection.names(of: keys) }

    public func index(of key: LegacyTag.Key) -> Int? { collection.index(of: key) }

    public func getBy(index: Int) -> LegacyTag { collection.getBy(index: index) }

    public func getBy(key: LegacyTag.Key) -> LegacyTag? { collection.getBy(key: key) }

    public func append(_ tag: LegacyTag) -> Int {
        defer { collectionChanged() }
        let index = collection.append(tag)
        notify(.added(new: index, tag: tag))
        return index
    }

    public func insert(_ tag: LegacyTag, at index: Int) {
        defer { collectionChanged() }
        collection.insert(tag, at: index)
        notify(.added(new: index, tag: tag))
    }

    public func remove(at index: Int) -> LegacyTag {
        defer { collectionChanged() }
        let tag = collection.remove(at: index)
        notify(.removed(old: index, tag: tag))
        return tag
    }

    public func rename(_ index: Int, name: String) {
        defer { collectionChanged() }
        collection.rename(index, name: name)
        notify(.changed(index: index, tag: collection.getBy(index: index)))
    }

    public func keySet(of indices: Set<Int>) -> Set<LegacyTag.Key> {
        Set(indices.map { collection.getBy(index: $0).key })
    }
}

extension LegacyTagsManager {

    private func collectionChanged() {
        os_log(.info, log: log, "collectionChanged - %{public}@", collection.description)
        AskForReview.maybe()
        configFile?.updateChangeCount(.done)
    }

    internal func configurationData() throws -> Data {
        os_log(.info, log: log, "configurationData")
        os_log(.info, log: log, "tags: %{public}@", collection.description)
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        if !restored {
            restored = true
            DispatchQueue.main.async { self.notify(.restored) }
        }
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loadConfigurationData")
        guard let data = contents as? Data else {
            restoreCollection(Self.defaultCollection)
            NotificationCenter.default.post(Notification(name: .tagsCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "has data")
        guard let value = try? PropertyListDecoder().decode(LegacyTagCollection.self, from: data) else {
            NotificationCenter.default.post(Notification(name: .tagsCollectionLoadFailure, object: nil))
            restoreCollection(Self.defaultCollection)
            return
        }

        os_log(.info, log: log, "properly decoded")
        restoreCollection(value)
    }

    private func restoreCollection(_ value: LegacyTagCollection) {
        collection = value.isEmpty ? Self.defaultCollection : value
        collection.cleanup()
        restored = true
        DispatchQueue.main.async { self.notify(.restored) }
    }

    private static var defaultCollection: LegacyTagCollection { LegacyTagCollection(tags: [LegacyTag.allTag]) }
}
