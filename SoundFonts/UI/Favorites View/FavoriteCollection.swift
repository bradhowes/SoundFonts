//
//  FavoriteCollection.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/27/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation

extension SettingKeys {
    static let favorites = SettingKey<Data>("favorites", defaultValue: Data())
}

/**
 Manages the collection of Favorite instances created by the user. Changes to the collection are saved, and they will be
 restored when the app relaunches.
 */
final class FavoriteCollection: NSObject {

    /// Reverse lookup of a Patch instance to a Favorite.
    ///
    /// - NOTE: For now this mapping means that there is only 1-1 relationship when there is a valid use-case for
    ///   1-many.
    private var favoriteMap = [Patch: Favorite]()
    /// Array of Favorite instances.
    private var favorites = [Favorite]()
    /// Number of Favorite instances.
    var count: Int { return favorites.count }

    /**
     Initialize new collection. Attempts to restore a previously-saved collection
     */
    override init() {
        super.init()
        do {
            let prev = Settings[.favorites]
            if let favorites = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(prev) as? [Favorite] {
                self.favorites = favorites
                self.favorites.forEach { favoriteMap[$0.patch] = $0 }
            }
        } catch {
            print(error)
        }

        if favorites.isEmpty {
            add(Favorite(patch: SoundFont.library[SoundFont.keys[0]]!.patches[0],
                         keyboardLowestNote: Note(midiNoteValue: 48)))
        }
    }

    /**
     Determine if given Patch instance belongs to a Favorite instance
    
     - parameter patch: Patch to check
     - returns: true if so
     */
    func isFavored(patch: Patch) -> Bool { return favoriteMap[patch] != nil }

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
    func getIndex(of favorite: Favorite) -> Int { return favorites.firstIndex(of: favorite) ?? -1 }
    
    /**
     Add a new favorite to the collection.
    
     - parameter favorite: the Favorite instance to add
     */
    func add(_ favorite: Favorite) {
        precondition(isFavored(patch: favorite.patch) == false, "Patch is already associated with a Favorite")
        favoriteMap[favorite.patch] = favorite
        favorites.append(favorite)
        save()
    }
    
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
    func remove(at index: Int) {
        let fave = favorites.remove(at: index)
        favoriteMap.removeValue(forKey: fave.patch)
        save()
    }

    /**
     Save the current collection to disk.
     */
    func save() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: favorites, requiringSecureCoding: false)
            Settings[.favorites] = data
        } catch {
            print(error)
        }
    }
}
