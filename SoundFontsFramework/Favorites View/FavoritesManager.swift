// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
public final class FavoritesManager: SubscriptionManager<FavoritesEvent>, Codable {

    private static let log = Logging.logger("FavMgr")

    private static let archivePath: URL = FileManager.default.privateDocumentsDirectory
        .appendingPathComponent("Favorites.plist")

    private var log: OSLog { Self.log }

    private var collection: FavoriteCollection

    /**
     Initialize new collection. Attempts to restore a previously-saved collection
     */
    public override init() {
        self.collection = Self.restore() ?? Self.build()
        super.init()
        save()
        os_log(.info, log: log, "collection size: %d", collection.count)
    }
}

// MARK: - Favorites protocol

extension FavoritesManager: Favorites {

    public var count: Int { collection.count }

    public func isFavored(soundFontPatch: SoundFontPatch) -> Bool { collection.isFavored(soundFontPatch: soundFontPatch) }

    public func index(of favorite: Favorite) -> Int { collection.index(of: favorite) }

    public func getBy(index: Int) -> Favorite { collection.getBy(index: index) }

    public func getBy(soundFontPatch: SoundFontPatch) -> Favorite? { collection.getBy(soundFontPatch: soundFontPatch) }

    public func add(soundFontPatch: SoundFontPatch, keyboardLowestNote note: Note) {
        let favorite = Favorite(soundFontPatch: soundFontPatch, keyboardLowestNote: note)
        collection.add(favorite: favorite)
        save()
        notify(.added(index: count - 1, favorite: favorite))
    }

    public func update(index: Int, with favorite: Favorite) {
        collection.replace(index: index, with: favorite)
        notify(.changed(index: index, favorite: favorite))
        save()
    }

    public func beginEdit(favorite: Favorite, view: UIView) {
        notify(.beginEdit(index: index(of: favorite), favorite: favorite, view: view))
    }

    public func move(from: Int, to: Int) {
        collection.move(from: from, to: to)
        save()
    }

    public func selected(index: Int) {
        notify(.selected(index: index, favorite: collection.getBy(index: index)))
    }

    public func remove(index: Int, bySwiping: Bool) {
        let favorite = collection.remove(index: index)
        save()
        notify(.removed(index: index, favorite: favorite, bySwiping: bySwiping))
    }

    public func removeAll(associatedWith soundFont: SoundFont) {
        collection.removeAll(associatedWith: soundFont)
        save()
        notify(.removedAll(associatedWith: soundFont))
    }

    public func count(associatedWith soundFont: SoundFont) -> Int {
        collection.count(associatedWith: soundFont)
    }
}

extension FavoritesManager {

    static func restore() -> FavoriteCollection? {
        os_log(.info, log: log, "attempting to restore collection")
        guard let data = try? Data(contentsOf: archivePath, options: .dataReadingMapped) else { return nil }
        os_log(.info, log: log, "loaded data")
        return try? PropertyListDecoder().decode(FavoriteCollection.self, from: data)
    }

    static func build() -> FavoriteCollection {
        FavoriteCollection()
    }

    /**
     Save the current collection to disk.
     */
    private func save() {
        do {
            let data = try PropertyListEncoder().encode(collection)
            let log = self.log

            os_log(.info, log: log, "archiving")
            DispatchQueue.global(qos: .background).async {
                os_log(.info, log: log, "obtained archive")
                do {
                    os_log(.info, log: log, "trying to save to disk")
                    try data.write(to: Self.archivePath, options: [.atomicWrite, .completeFileProtection])
                    os_log(.info, log: log, "saving OK")
                } catch {
                    os_log(.error, log: log, "saving FAILED")
                }
            }
        } catch {
            os_log(.error, log: Self.log, "archiving FAILED")
        }
    }
}