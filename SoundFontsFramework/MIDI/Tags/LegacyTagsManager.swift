// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib

public final class LegacyTagsManager: SubscriptionManager<TagsEvent> {
    private static let log = Logging.logger("TagsMgr")
    private var log: OSLog { Self.log }
    private var configFile: TagsConfigFile?
    private lazy var collection = LegacyTagCollection(tags: [], markDirty: self.markDirty) {
        didSet { os_log(.debug, log: log, "collection changed: %{public}s", collection.description) }
    }

    public private(set) var restored = false

    public init() {
        super.init()
        DispatchQueue.global(qos: .background).async { self.configFile = TagsConfigFile(tagsManager: self) }
    }
}

extension LegacyTagsManager {

    private func markDirty() {
        configFile?.updateChangeCount(.done)
    }
}

extension LegacyTagsManager {

    internal func configurationData() throws -> Data {
        os_log(.info, log: log, "configurationData")
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loadConfigurationData")
        guard let data = contents as? Data else {
            restoreCollection(self.collection)
            NotificationCenter.default.post(Notification(name: .tagsCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "has Data")
        guard let collection = try? PropertyListDecoder().decode(LegacyTagCollection.self, from: data) else {
            NotificationCenter.default.post(Notification(name: .tagsCollectionLoadFailure, object: nil))
            restoreCollection(self.collection)
            return
        }

        collection.markDirty = markDirty

        os_log(.info, log: log, "properly decoded")
        restoreCollection(collection)
    }

    private func restoreCollection(_ collection: LegacyTagCollection) {
        self.collection = collection
        restored = true
        DispatchQueue.main.async { self.notify(.restored) }
    }
}
