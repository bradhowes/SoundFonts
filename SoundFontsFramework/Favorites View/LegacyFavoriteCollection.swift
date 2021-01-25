// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Collection of Favorite instances created by the user.
 */
final public class LegacyFavoriteCollection: Codable, CustomStringConvertible {

    public var description: String {
        "[" + favorites.map { "\(String.pointer($0)) '\($0.presetConfig.name)'" }.joined(separator: ",") + "]"
    }

    private var favorites: [LegacyFavorite]

    /// Number of favorites defined
    var count: Int { favorites.count }

    init() {
        self.favorites = []
    }

    /**
     Determine if the given soundFont/patch combination is associated with a favorite.

     - parameter soundFontPatch: soundFont/patch to look for
     - returns: true if so
     */
    func isFavored(soundFontAndPatch: SoundFontAndPatch) -> Bool {
        getBy(soundFontAndPatch: soundFontAndPatch) != nil
    }

    /**
     Obtain the index of the given favorite in the collection.

     - parameter favorite: the favorite to look for
     - returns: the index in the collection
     */
    func index(of favorite: LegacyFavorite) -> Int {
        favorites.firstIndex(of: favorite)!
    }

    /**
     Obtain the favorite at the given index.

     - parameter index: the index to use
     - returns: the favorite instance
     */
    func getBy(index: Int) -> LegacyFavorite { favorites[index] }

    /**
     Obtain the first favorite associated with the given soundFont/patch combination.

     - parameter soundFontPatch: soundFont/patch to look for
     - returns: the favorite found or nil if no match
     */
    func getBy(soundFontAndPatch: SoundFontAndPatch) -> LegacyFavorite? {
        favorites.first { soundFontAndPatch == $0.soundFontAndPatch }
    }

    /**
     Add a favorite to the end of the collection.

     - parameter favorite: the new favorite to add
     */
    func add(favorite: LegacyFavorite) {
        AskForReview.maybe()
        favorites.append(favorite)
    }

    /**
     Replace an existing entry with a new value.

     - parameter index: the location to replace
     - parameter favorite: the new value to store
     */
    func replace(index: Int, with favorite: LegacyFavorite) {
        favorites[index] = favorite
    }

    func move(from: Int, to: Int) {
        favorites.insert(favorites.remove(at: from), at: to)
        AskForReview.maybe()
    }

    func remove(index: Int) -> LegacyFavorite {
        let favorite = favorites.remove(at: index)
        AskForReview.maybe()
        return favorite
    }

    func removeAll(associatedWith soundFontKey: LegacySoundFont.Key) {
        findAll(associatedWith: soundFontKey).forEach { self.remove(favorite: $0) }
    }

    func count(associatedWith soundFontKey: LegacySoundFont.Key) -> Int {
        findAll(associatedWith: soundFontKey).count
    }
}

extension LegacyFavoriteCollection {

    private func remove(favorite: LegacyFavorite) {
        guard let index = favorites.firstIndex(of: favorite) else { return }
        favorites.remove(at: index)
    }

    private func findAll(associatedWith soundFontKey: LegacySoundFont.Key) -> [LegacyFavorite] {
        favorites.filter { $0.soundFontAndPatch.soundFontKey == soundFontKey }
    }
}
