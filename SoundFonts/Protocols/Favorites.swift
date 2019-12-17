// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 The different events which are emitted by a Favorites collection when the collection changes.
*/
enum FavoritesEvent {

    /// New Favorite added to the collection
    case added(index: Int, favorite: Favorite)
    /// Favorite selected
    case selected(index: Int, favorite: Favorite)
    /// Favorite being edited
    case beginEdit(index: Int, favorite: Favorite, view: UIView)
    /// Favorite changed
    case changed(index: Int, favorite: Favorite)
    /// Favorite removed
    case removed(index: Int, favorite: Favorite, bySwiping: Bool)
    /// Side-effect of a SoundFont being removed -- removal of all associaed Favorites
    case removedAll(associatedWith: SoundFont)
}

/**
 Actions available on a collection of Favorite instances. Supports subscribing to changes.
 */
protocol Favorites {

    var count: Int {get}

    func isFavored(soundFontPatch: SoundFontPatch) -> Bool

    func index(of favorite: Favorite) -> Int
    func getBy(index: Int) -> Favorite
    func getBy(soundFontPatch: SoundFontPatch) -> Favorite?

    /**
     Create a new Favorite instance with the given parameters
    
     - parameter patch: the Patch to associate with
     - parameter keyboardLowestNote: the lowest note of the keyboard
     */
    func add(soundFontPatch: SoundFontPatch, keyboardLowestNote: Note)

    func beginEdit(favorite: Favorite, view: UIView)

    func update(index: Int, with: Favorite)

    func move(from: Int, to: Int)

    func selected(index: Int)

    func remove(index: Int, bySwiping: Bool)

    func removeAll(associatedWith: SoundFont)

    func count(associatedWith: SoundFont) -> Int

    @discardableResult
    func subscribe<O: AnyObject>(_ subscriber: O, closure: @escaping (FavoritesEvent) -> Void) -> SubscriberToken
}
