// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
public final class LegacyFavoritesManager: SubscriptionManager<FavoritesEvent> {

    private static let log = Logging.logger("FavMgr")

    private var log: OSLog { Self.log }

    private var configFile: FavoritesConfigFile?

    private var collection: LegacyFavoriteCollection = LegacyFavoriteCollection() {
        didSet {
            os_log(.debug, log: log, "collection changed: %{public}s", collection.description)
        }
    }

    /**
     Initialize new collection. Attempts to restore a previously-saved collection
     */
    public init() {
        super.init()
        DispatchQueue.global(qos: .background).async { self.configFile = FavoritesConfigFile(favoritesManager: self) }
    }

    public func validate(_ favorite: LegacyFavorite) -> Bool { collection.validate(favorite) }
}

// MARK: - Favorites protocol

extension LegacyFavoritesManager: Favorites {

    public var count: Int { collection.count }

    public func isFavored(soundFontAndPatch: SoundFontAndPatch) -> Bool {
        collection.isFavored(soundFontAndPatch: soundFontAndPatch)
    }

    public func index(of favorite: LegacyFavorite) -> Int { collection.index(of: favorite) }

    public func getBy(index: Int) -> LegacyFavorite { collection.getBy(index: index) }

    public func getBy(soundFontAndPatch: SoundFontAndPatch?) -> LegacyFavorite? {
        collection.getBySFP(soundFontAndPatch: soundFontAndPatch)
    }

    public func add(name: String, soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote note: Note?) {
        let favorite = LegacyFavorite(name: name, soundFontAndPatch: soundFontAndPatch, keyboardLowestNote: note)
        collection.add(favorite: favorite)
        notify(.added(index: count - 1, favorite: favorite))
        markDirty()
    }

    public func update(index: Int, with favorite: LegacyFavorite) {
        collection.replace(index: index, with: favorite)
        notify(.changed(index: index, favorite: favorite))
        markDirty()
    }

    public func beginEdit(config: FavoriteEditor.Config) {
        notify(.beginEdit(config: config))
    }

    public func move(from: Int, to: Int) {
        collection.move(from: from, to: to)
        markDirty()
    }

    public func selected(index: Int) {
        notify(.selected(index: index, favorite: collection.getBy(index: index)))
    }

    public func remove(index: Int, bySwiping: Bool) {
        let favorite = collection.remove(index: index)
        notify(.removed(index: index, favorite: favorite, bySwiping: bySwiping))
        markDirty()
    }

    public func removeAll(associatedWith soundFont: LegacySoundFont) {
        collection.removeAll(associatedWith: soundFont)
        notify(.removedAll(associatedWith: soundFont))
        markDirty()
    }

    public func count(associatedWith soundFont: LegacySoundFont) -> Int {
        collection.count(associatedWith: soundFont)
    }
}

extension LegacyFavoritesManager {

    internal func configurationData() throws -> Data {
        os_log(.info, log: log, "configurationData")
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loadConfigurationData")
        guard let data = contents as? Data else {
            NotificationCenter.default.post(Notification(name: .favoritesCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "has Data")
        guard let collection = try? PropertyListDecoder().decode(LegacyFavoriteCollection.self, from: data) else {
            NotificationCenter.default.post(Notification(name: .favoritesCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "properly decoded")
        self.collection = collection
        DispatchQueue.main.async { self.notify(.restored) }
    }

    /**
     Mark the current collection as dirty so it will get written to disk.
     */
    private func markDirty() {
        configFile?.updateChangeCount(.done)
    }
}
