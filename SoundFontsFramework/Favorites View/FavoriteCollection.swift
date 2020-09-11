// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Collection of Favorite instances created by the user.
 */
final public class LegacyFavoriteCollection: Codable {

    private var favorites: [LegacyFavorite]
    private var reverseLookup: [SoundFontAndPatch: LegacyFavorite]

    /// Number of favorites defined
    var count: Int { favorites.count }

    init() {
        self.favorites = []
        self.reverseLookup = [:]
    }

    public func validate(_ legacyFavorite: LegacyFavorite) -> Bool {
        guard let held = getBy(soundFontAndPatch: legacyFavorite.soundFontAndPatch) else { return false }
        return held == legacyFavorite
    }

    /**
     Determine if the given soundFont/patch combination is associated with a favorite.

     - parameter soundFontPatch: soundFont/patch to look for
     - returns: true if so
     */
    func isFavored(soundFontAndPatch: SoundFontAndPatch) -> Bool { reverseLookup[soundFontAndPatch] != nil }

    /**
     Obtain the index of the given favorite in the collection.

     - parameter favorite: the favorite to look for
     - returns: the index in the collection
     */
    func index(of favorite: LegacyFavorite) -> Int { favorites.firstIndex(of: favorite)! }

    /**
     Obtain the favorite at the given index.

     - parameter index: the index to use
     - returns: the favorite instance
     */
    func getBy(index: Int) -> LegacyFavorite { favorites[index] }

    /**
     Obtain the favorite associated with the given soundFont/patch combination.

     - parameter soundFontPatch: soundFont/patch to look for
     - returns: the favorite found or nil if no match
     */
    func getBy(soundFontAndPatch: SoundFontAndPatch?) -> LegacyFavorite? {
        guard let soundFontAndPatch = soundFontAndPatch else { return nil }
        return reverseLookup[soundFontAndPatch]
    }

    /**
     Add a favorite to the end of the collection.

     - parameter favorite: the new favorite to add
     */
    func add(favorite: LegacyFavorite) {
        reverseLookup[favorite.soundFontAndPatch] = favorite
        AskForReview.maybe()
        favorites.append(favorite)
    }

    /**
     Replace an existing entry with a new value.

     - parameter index: the location to replace
     - parameter favorite: the new value to store
     */
    func replace(index: Int, with favorite: LegacyFavorite) {
        reverseLookup.removeValue(forKey: favorites[index].soundFontAndPatch)
        favorites[index] = favorite
        reverseLookup[favorite.soundFontAndPatch] = favorite
    }

    func move(from: Int, to: Int) {
        favorites.insert(favorites.remove(at: from), at: to)
        AskForReview.maybe()
    }

    func remove(index: Int) -> LegacyFavorite {
        let favorite = favorites.remove(at: index)
        reverseLookup.removeValue(forKey: favorite.soundFontAndPatch)
        AskForReview.maybe()
        return favorite
    }

    func removeAll(associatedWith soundFont: SoundFont) {
        findAll(associatedWith: soundFont).forEach { self.remove(favorite: $0) }
    }

    func count(associatedWith soundFont: SoundFont) -> Int {
        findAll(associatedWith: soundFont).count
    }
}

extension LegacyFavoriteCollection {

    private func remove(favorite: LegacyFavorite) {
        guard let index = favorites.firstIndex(of: favorite) else { return }
        favorites.remove(at: index)
        reverseLookup.removeValue(forKey: favorite.soundFontAndPatch)
    }

    private func findAll(associatedWith soundFont: SoundFont) -> [LegacyFavorite] {
        favorites.filter { $0.soundFontAndPatch.soundFontKey == soundFont.key }
    }
}
