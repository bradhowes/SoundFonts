// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
public final class LegacyFavoritesManager: SubscriptionManager<FavoritesEvent> {
    private let log = Logging.logger("FavMgr")

    private var configFile: UIDocument?
    private var collection: LegacyFavoriteCollection {
        didSet { os_log(.debug, log: log, "collection changed: %{public}s", collection.description) }
    }

    public private(set) var restored = false {
        didSet { os_log(.debug, log: log, "restored: %{public}@", collection.description) }
    }

    public init() {
        os_log(.info, log: log, "init")
        self.collection = Self.defaultCollection
        super.init()
        DispatchQueue.global(qos: .userInitiated).async {
            self.configFile = ConfigFile<Self>(manager: self)
        }
    }
}

// MARK: - Favorites protocol

extension LegacyFavoritesManager: Favorites {

    public var count: Int { collection.count }

    public func index(of key: LegacyFavorite.Key) -> Int? { collection.index(of: key) }

    public func getBy(index: Int) -> LegacyFavorite { collection.getBy(index: index) }

    public func getBy(key: LegacyFavorite.Key) -> LegacyFavorite { collection.getBy(key: key) }

    public func add(favorite: LegacyFavorite) {
        defer { collectionChanged() }
        collection.add(favorite: favorite)
        notify(.added(index: count - 1, favorite: favorite))
    }

    public func update(index: Int, config: PresetConfig) {
        defer { collectionChanged() }
        let favorite = collection.getBy(index: index)
        favorite.presetConfig = config
        collection.replace(index: index, with: favorite)
        notify(.changed(index: index, favorite: favorite))
    }

    public func beginEdit(config: FavoriteEditor.Config) {
        notify(.beginEdit(config: config))
    }

    public func move(from: Int, to: Int) {
        defer { collectionChanged() }
        collection.move(from: from, to: to)
    }

    public func selected(index: Int) {
        notify(.selected(index: index, favorite: collection.getBy(index: index)))
    }

    public func remove(key: LegacyFavorite.Key) {
        guard let index = collection.index(of: key) else { return }
        defer { collectionChanged() }
        let favorite = collection.remove(at: index)
        notify(.removed(index: index, favorite: favorite))
    }

    public func removeAll(associatedWith soundFont: LegacySoundFont) {
        defer { collectionChanged() }
        collection.removeAll(associatedWith: soundFont.key)
        notify(.removedAll(associatedWith: soundFont))
    }

    public func count(associatedWith soundFont: LegacySoundFont) -> Int {
        collection.count(associatedWith: soundFont.key)
    }

    public func setVisibility(key: LegacyFavorite.Key, state isVisible: Bool) {
        defer { collectionChanged() }
        let favorite = collection.getBy(key: key)
        favorite.presetConfig.isHidden = !isVisible
    }

    public func setEffects(favorite: LegacyFavorite, delay: DelayConfig?, reverb: ReverbConfig?) {
        os_log(.debug, log: log, "setEffects - %d %{public}s %{public}s", favorite.presetConfig.name,
               delay?.description ?? "nil", reverb?.description ?? "nil")
        defer { collectionChanged() }
        favorite.presetConfig.delayConfig = delay
        favorite.presetConfig.reverbConfig = reverb
    }
}

extension LegacyFavoritesManager: ConfigFileManager {

    var filename: String { "Favorites.plist" }

    internal func configurationData() throws -> Any {
        os_log(.info, log: log, "configurationData")
        os_log(.info, log: log, "favorites: %{public}@", collection.description)
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
            NotificationCenter.default.post(Notification(name: .favoritesCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "has data")
        guard let value = try? PropertyListDecoder().decode(LegacyFavoriteCollection.self, from: data) else {
            NotificationCenter.default.post(Notification(name: .favoritesCollectionLoadFailure, object: nil))
            return
        }

        os_log(.info, log: log, "properly decoded")
        restoreCollection(value)
    }
}

extension LegacyFavoritesManager {

    private func collectionChanged() {
        os_log(.info, log: log, "collectionChanged - %{public}@", collection.description)
        AskForReview.maybe()
        configFile?.updateChangeCount(.done)
    }

    private func restoreCollection(_ value: LegacyFavoriteCollection) {
        collection = value
        restored = true
        DispatchQueue.main.async { self.notify(.restored) }
    }

    private static var defaultCollection: LegacyFavoriteCollection {
        LegacyFavoriteCollection()
    }
}
