// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
final class LegacyFavoritesManager: SubscriptionManager<FavoritesEvent> {
    private let log = Logging.logger("FavMgr")

    private var observer: ConfigFileObserver!
    var restored: Bool { observer.restored }

    var collection: LegacyFavoriteCollection {
        precondition(observer.restored)
        return observer.favorites
    }

    private var configFileObserver: NSKeyValueObservation?

    init(_ consolidatedConfigFile: ConsolidatedConfigFile) {
        super.init()
        observer = ConfigFileObserver(configFile: consolidatedConfigFile, closure: collectionRestored)
    }
}

// MARK: - Favorites protocol

extension LegacyFavoritesManager: Favorites {

    var count: Int { collection.count }

    func contains(key: LegacyFavorite.Key) -> Bool { collection.contains(key: key) }

    func index(of key: LegacyFavorite.Key) -> Int { collection.index(of: key) }

    func getBy(index: Int) -> LegacyFavorite { collection.getBy(index: index) }

    func getBy(key: LegacyFavorite.Key) -> LegacyFavorite { collection.getBy(key: key) }

    func add(favorite: LegacyFavorite) {
        defer { collectionChanged() }
        collection.add(favorite: favorite)
        notify(.added(index: count - 1, favorite: favorite))
    }

    func update(index: Int, config: PresetConfig) {
        defer { collectionChanged() }
        let favorite = collection.getBy(index: index)
        favorite.presetConfig = config
        collection.replace(index: index, with: favorite)
        notify(.changed(index: index, favorite: favorite))
    }

    func beginEdit(config: FavoriteEditor.Config) {
        notify(.beginEdit(config: config))
    }

    func move(from: Int, to: Int) {
        defer { collectionChanged() }
        collection.move(from: from, to: to)
    }

    func selected(index: Int) {
        notify(.selected(index: index, favorite: collection.getBy(index: index)))
    }

    func remove(key: LegacyFavorite.Key) {
        defer { collectionChanged() }
        let index = collection.index(of: key)
        let favorite = collection.remove(at: index)
        notify(.removed(index: index, favorite: favorite))
    }

    func removeAll(associatedWith soundFont: LegacySoundFont) {
        defer { collectionChanged() }
        collection.removeAll(associatedWith: soundFont.key)
        notify(.removedAll(associatedWith: soundFont))
    }

    func count(associatedWith soundFont: LegacySoundFont) -> Int {
        collection.count(associatedWith: soundFont.key)
    }

    func setVisibility(key: LegacyFavorite.Key, state isVisible: Bool) {
        defer { collectionChanged() }
        let favorite = collection.getBy(key: key)
        favorite.presetConfig.isHidden = !isVisible
    }

    func setEffects(favorite: LegacyFavorite, delay: DelayConfig?, reverb: ReverbConfig?) {
        os_log(.debug, log: log, "setEffects - %d %{public}s %{public}s", favorite.presetConfig.name,
               delay?.description ?? "nil", reverb?.description ?? "nil")
        defer { collectionChanged() }
        favorite.presetConfig.delayConfig = delay
        favorite.presetConfig.reverbConfig = reverb
    }

    func validate(_ soundFonts: SoundFonts) {
        var invalidFavoriteKeys = [LegacyFavorite.Key]()
        for index in 0..<self.count {
            let favorite = self.getBy(index: index)
            if let preset = soundFonts.resolve(soundFontAndPatch: favorite.soundFontAndPatch) {
                if !preset.favorites.contains(favorite.key) {
                    os_log(.error, log: log, "linking favorite - '%{public}s'", favorite.presetConfig.name)
                    preset.favorites.append(favorite.key)
                }
            }
            else {
                os_log(.error, log: log, "found orphan favorite - '%{public}s'", favorite.presetConfig.name)
                invalidFavoriteKeys.append(favorite.key)
            }
        }

        for key in invalidFavoriteKeys {
            self.remove(key: key)
        }
    }
}

extension LegacyFavoritesManager {

    static var defaultCollection: LegacyFavoriteCollection { LegacyFavoriteCollection() }

    private func collectionChanged() {
        os_log(.info, log: log, "collectionChanged - %{public}@", collection.description)
        observer.markChanged()
    }

    private func collectionRestored() {
        os_log(.info, log: self.log, "restored")
        DispatchQueue.main.async { self.notify(.restored) }
    }
}
