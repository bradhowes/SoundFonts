// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib

public final class LegacyTagsManager: SubscriptionManager<TagsEvent> {
    private let log = Logging.logger("TagsMgr")

    private var configFile: TagsConfigFile?
    private var collection: LegacyTagCollection! {
        didSet { os_log(.debug, log: log, "collection changed: %{public}s", collection.description) }
    }

    public private(set) var restored = false

    public init() {
        super.init()
        DispatchQueue.global(qos: .userInitiated).async { self.configFile = TagsConfigFile(tagsManager: self) }
    }
}

extension LegacyTagsManager: Tags {

    public var isEmpty: Bool { collection.isEmpty }

    public var count: Int { collection.count }

    public func names(of keys: [LegacyTag.Key]) -> [String] { collection.names(of: keys) }

    public func index(of key: LegacyTag.Key) -> Int? { collection.index(of: key) }

    public func getBy(index: Int) -> LegacyTag { collection.getBy(index: index) }

    public func getBy(key: LegacyTag.Key) -> LegacyTag? { collection.getBy(key: key) }

    public func add(tag: LegacyTag) -> Int {
        defer { collectionChanged() }
        return collection.add(tag)
    }

    public func remove(index: Int) -> LegacyTag {
        defer { collectionChanged() }
        return collection.remove(index)
    }

    public func rename(index: Int, name: String) {
        defer { collectionChanged() }
        collection.rename(index, name: name)
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
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loadConfigurationData")
        guard let data = contents as? Data else {
            restoreCollection(defaultCollection)
            NotificationCenter.default.post(Notification(name: .tagsCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "has Data")
        guard let value = try? PropertyListDecoder().decode(LegacyTagCollection.self, from: data) else {
            NotificationCenter.default.post(Notification(name: .tagsCollectionLoadFailure, object: nil))
            restoreCollection(defaultCollection)
            return
        }

        os_log(.info, log: log, "properly decoded")
        restoreCollection(value)
    }

    private func restoreCollection(_ value: LegacyTagCollection) {
        collection = value.isEmpty ? defaultCollection : value
        restored = true
        DispatchQueue.main.async { self.notify(.restored) }
    }

    private var defaultCollection: LegacyTagCollection { LegacyTagCollection(tags: [LegacyTag.allTag]) }
}
