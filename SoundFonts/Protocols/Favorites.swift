// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

enum FavoritesEvent {
    case added(index: Int, favorite: Favorite)
    case selected(index: Int, favorite: Favorite)
    case beginEdit(index: Int, favorite: Favorite, view: UIView)
    case changed(index: Int, favorite: Favorite)
    case removed(index: Int, favorite: Favorite, bySwiping: Bool)
    case removedAll(associatedWith: SoundFont)
}

protocol Favorites {

    /**
     Determine if the given Patch instance is associated with a Favorite instance
    
     - parameter patch: the Patch to look for
     - returns: true if it is associated with a Favorite instance
     */
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
    func subscribe<O:AnyObject>(_ subscriber: O, closure: @escaping (FavoritesEvent)->Void) -> SubscriberToken
}
