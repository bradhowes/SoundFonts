// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Collection of Favorite instances created by the user.
 */
struct FavoriteCollection: Codable {

    private var favorites: [Favorite]
    private var reverseLookup: [SoundFontPatch:Favorite]

    /// Number of favorites defined
    var count: Int { favorites.count }

    init() {
        self.favorites = []
        self.reverseLookup = [:]
    }

    /**
     Determine if the given soundFont/patch combination is associated with a favorite.

     - parameter soundFontPatch: soundFont/patch to look for
     - returns true if so
     */
    func isFavored(soundFontPatch: SoundFontPatch) -> Bool { reverseLookup[soundFontPatch] != nil }

    /**
     Obtain the index of the given favorite in the collection.

     - parameter favorite: the favorite to look for
     - returns the index in the collection
     */
    func index(of favorite: Favorite) -> Int { favorites.firstIndex(of: favorite)! }

    /**
     Obtain the favorite at the given index.

     - parameter index: the index to use
     - returns the favorite instance
     */
    func getBy(index: Int) -> Favorite { favorites[index] }

    /**
     Obtain the favorite associated with the given soundFont/patch combination.

     - parameter soundFontPatch: soundFont/patch to look for
     - returns the favorite found or nil if no match
     */
    func getBy(soundFontPatch: SoundFontPatch) -> Favorite? { reverseLookup[soundFontPatch] }

    /**
     Add a favorite to the end of the collection.

     - parameter favorite: the new favorite to add
     */
    mutating func add(favorite: Favorite) {
        reverseLookup[favorite.soundFontPatch] = favorite
        favorites.append(favorite)
    }

    /**
     Replace an existing entry with a new value.

     - parameter index: the location to replace
     - parameter favorite: the new value to store
     */
    mutating func replace(index: Int, with favorite: Favorite) {
        favorites[index] = favorite
    }

    mutating func move(from: Int, to: Int) {
        let favorite = favorites.remove(at: from)
        favorites.insert(favorite, at: to)
    }

    mutating func remove(index: Int) -> Favorite {
        let favorite = favorites.remove(at: index)
        reverseLookup.removeValue(forKey: favorite.soundFontPatch)
        return favorite
    }

    mutating func removeAll(associatedWith soundFont: SoundFont) {
        findAll(associatedWith: soundFont).forEach { self.remove(favorite: $0) }
    }

    func count(associatedWith soundFont: SoundFont) -> Int {
        findAll(associatedWith: soundFont).count
    }
}

extension FavoriteCollection {

    mutating private func remove(favorite: Favorite) {
        guard let index = favorites.firstIndex(of: favorite) else { return }
        favorites.remove(at: index)
        reverseLookup.removeValue(forKey: favorite.soundFontPatch)
    }

    private func findAll(associatedWith soundFont: SoundFont) -> [Favorite] {
        favorites.filter { $0.soundFontPatch.soundFont.uuid == soundFont.uuid }
    }
}
