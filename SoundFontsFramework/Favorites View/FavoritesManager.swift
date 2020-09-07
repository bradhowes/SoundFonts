// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
public final class FavoritesManager: SubscriptionManager<FavoritesEvent> {

    private static let log = Logging.logger("FavMgr")

    static public var loadError: Notification.Name?

    private var log: OSLog { Self.log }
    private var collection: FavoriteCollection

    /**
     Initialize new collection. Attempts to restore a previously-saved collection
     */
    public init() {
        self.collection = FavoriteCollection()
        super.init()
    }

    public func validate(_ favorite: Favorite) -> Bool { collection.validate(favorite) }
}

// MARK: - Favorites protocol

extension FavoritesManager: Favorites {

    public var count: Int { collection.count }

    public func isFavored(soundFontAndPatch: SoundFontAndPatch) -> Bool {
        collection.isFavored(soundFontAndPatch: soundFontAndPatch)
    }

    public func index(of favorite: Favorite) -> Int { collection.index(of: favorite) }

    public func getBy(index: Int) -> Favorite { collection.getBy(index: index) }

    public func getBy(soundFontAndPatch: SoundFontAndPatch?) -> Favorite? {
        collection.getBy(soundFontAndPatch: soundFontAndPatch)
    }

    public func add(name: String, soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote note: Note?) {
        let favorite = Favorite(name: name, soundFontAndPatch: soundFontAndPatch, keyboardLowestNote: note)
        collection.add(favorite: favorite)
        notify(.added(index: count - 1, favorite: favorite))
    }

    public func update(index: Int, with favorite: Favorite) {
        collection.replace(index: index, with: favorite)
        notify(.changed(index: index, favorite: favorite))
    }

    public func beginEdit(config: FavoriteEditor.Config) {
        notify(.beginEdit(config: config))
    }

    public func move(from: Int, to: Int) {
        collection.move(from: from, to: to)
    }

    public func selected(index: Int) {
        notify(.selected(index: index, favorite: collection.getBy(index: index)))
    }

    public func remove(index: Int, bySwiping: Bool) {
        let favorite = collection.remove(index: index)
        notify(.removed(index: index, favorite: favorite, bySwiping: bySwiping))
    }

    public func removeAll(associatedWith soundFont: SoundFont) {
        collection.removeAll(associatedWith: soundFont)
        notify(.removedAll(associatedWith: soundFont))
    }

    public func count(associatedWith soundFont: SoundFont) -> Int {
        collection.count(associatedWith: soundFont)
    }
}

extension FavoritesManager {

    internal func configurationData() throws -> Data {
        os_log(.info, log: log, "archiving")
        let data = try PropertyListEncoder().encode(collection)
        os_log(.info, log: log, "done - %d", data.count)
        return data
    }

    internal func loadConfigurationData(contents: Any) throws {
        os_log(.info, log: log, "loading configuration")
        if let data = contents as? Data {
            os_log(.info, log: log, "has Data")
            if let collection = try? PropertyListDecoder().decode(FavoriteCollection.self, from: data) {
                os_log(.info, log: log, "properly decoded")
                self.collection = collection
                notify(.restored)
                return
            }
        }
        NotificationCenter.default.post(Notification(name: .favoritesCollectionLoadFailure, object: nil))
    }
}
