// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import os

extension SettingKeys {
    static let favorites = SettingKey<Data>("favorites", defaultValue: Data())
}

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
final class FavoriteCollection: Codable {

    private static let logger = Logging.logger("FavCo")

    private static let archivePath: URL = FileManager.default.localDocumentsDirectory
        .appendingPathComponent("favorites.plist")

    /// Reverse lookup of a Patch instance to a Favorite.
    ///
    /// - NOTE: For now this mapping means that there is only 1-1 relationship when there is a valid use-case for
    ///   1-many.
    private var favoriteMap = [Patch:Favorite]()

    /// Array of Favorite instances.
    private var favorites = [Favorite]()

    /// Number of Favorite instances.
    var count: Int { return favorites.count }

    enum FakeError: Error {
        case bad
    }

    static var shared: FavoriteCollection = build()

    private static func build() -> FavoriteCollection {
        do {
            os_log(.info, log: logger, "attempting to restore collection")
            let data = try Data(contentsOf: archivePath, options: .dataReadingMapped)
            os_log(.info, log: logger, "loaded data")
            return try PropertyListDecoder().decode(FavoriteCollection.self, from: data)
        } catch {
            os_log(.info, log: logger, "failed to restore collection")
        }

        os_log(.info, log: logger, "creating initial collection")
        return FavoriteCollection()
    }

    /**
     Initialize new collection. Attempts to restore a previously-saved collection
     */
    private init() {
        save()
    }

    /**
     Determine if given Patch instance belongs to a Favorite instance
    
     - parameter patch: Patch to check
     - returns: true if so
     */
    func isFavored(patch: Patch) -> Bool { return getFavorite(patch: patch) != nil }

    /**
     Obtain the Favorite that is associated with the given Patch.

     - parameter patch: the Patch to look for
     - returns the Favorite found or nil if none
     */
    func getFavorite(patch: Patch) -> Favorite? { return favoriteMap[patch] }

    /**
     Obtain the Favorite instance at the given index
    
     - parameter index: the index to use
     - returns: the Favorite at the index
     */
    subscript(index: Int) -> Favorite { return favorites[index] }

    /**
     Obtain the Favorite instance associated with the given Patch

     - parameter patch: the Patch to look for
     - returns: the Favorite found or nil no match
     */
    subscript(patch: Patch?) -> Favorite? { return patch != nil ? favoriteMap[patch!] : nil }

    /**
     Obtain the index of the given Favorite instance.
    
     - parameter favorite: the Favorite to look for
     - returns: the index of the Favorite or -1 if not found
     */
    func getIndex(of favorite: Favorite) -> Int {
        os_log(.info, log: Self.logger, "getIndex: %s", favorite.description)
        for fav in favorites.enumerated() {
            os_log(.info, log: Self.logger, "-- %d %s", fav.0, fav.1.description)
            if (fav.1.name == favorite.name) {
                return fav.0
            }
        }

        fatalError("favorite is *not* found")
    }
    
    /**
     Add a new favorite to the collection.
    
     - parameter favorite: the Favorite instance to add
     */
    func add(_ favorite: Favorite) {
        precondition(isFavored(patch: favorite.patch) == false, "Patch is already associated with a Favorite")
        os_log(.info, log: Self.logger, "adding '%s'", favorite.name)
        favoriteMap[favorite.patch] = favorite
        favorites.append(favorite)
        save()
    }

    /**
     Update the collection by moving an entry from one slot to another.

     - parameter from: the source slot
     - parameter to: the destination slot
     */
    func move(from: Int, to: Int) {
        let favorite = favorites.remove(at: from)
        favorites.insert(favorite, at: to)
        save()
    }

    /**
     Remove an existing Favorite from the collection
    
     - parameter patch: the Patch instance to search for
     */
    func remove(patch: Patch) -> Favorite {
        precondition(isFavored(patch: patch) == true, "Patch is not associated with a Favorite")
        let fave = favoriteMap.removeValue(forKey: patch)!
        let index = favorites.firstIndex(of: fave)!
        favorites.remove(at: index)
        save()
        return fave
    }

    /**
     Remove an existing Favorite from the collection
    
     - parameter index: the index of the Favorite to remove
     */
    func removeAll(associatedWith soundFont: SoundFont) -> [Favorite] {
        let matching = favorites.filter { $0.patch.soundFont == soundFont }
        return matching.map { self.remove(patch: $0.patch) }
    }

    /**
     Save the current collection to disk.
     */
    func save() {
        do {
            os_log(.info, log: Self.logger, "archiving")

            // NOTE: acquire the encoding in the main thread to guarantee thread-safe access. Do the rest in the
            // background.
            let data = try PropertyListEncoder().encode(self)
            DispatchQueue.global(qos: .background).async {
                os_log(.info, log: Self.logger, "obtained archive")
                do {
                    os_log(.info, log: Self.logger, "trying to save to disk")
                    try data.write(to: Self.archivePath, options: [.atomicWrite, .completeFileProtection])
                    os_log(.info, log: Self.logger, "saving OK")
                } catch {
                    os_log(.error, log: Self.logger, "saving FAILED")
                }
            }
        } catch {
            os_log(.error, log: Self.logger, "archiving FAILED")
        }
    }
}
