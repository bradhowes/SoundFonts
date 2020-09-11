// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 The different events which are emitted by a Favorites collection when the collection changes.
*/
public enum FavoritesEvent {
    case added(index: Int, favorite: LegacyFavorite)
    case selected(index: Int, favorite: LegacyFavorite)
    case beginEdit(config: FavoriteEditor.Config)
    case changed(index: Int, favorite: LegacyFavorite)
    case removed(index: Int, favorite: LegacyFavorite, bySwiping: Bool)
    case removedAll(associatedWith: SoundFont)
    case restored
}

/**
 Actions available on a collection of Favorite instances. Supports subscribing to changes.
 */
public protocol Favorites {

    /// Get number of favorites
    var count: Int {get}

    /**
     Determine if the given SoundFontPatch is associated with a Favorite

     - parameter soundFontAndPatch: what to look for
     - returns: true if so
     */
    func isFavored(soundFontAndPatch: SoundFontAndPatch) -> Bool

    /**
     Obtain the index of the given Favorite in the collection.

     - parameter favorite: what to look for
     - returns: the position of the Favorite
     */
    func index(of favorite: LegacyFavorite) -> Int

    /**
     Obtain the Favorite at the given index

     - parameter index: the location to get
     - returns: Favorite at the index
     */
    func getBy(index: Int) -> LegacyFavorite

    /**
     Get the Favorite associated with the given SoundFontPatch

     - parameter soundFontAndPatch: what to look for
     - returns: optional Favorite instance
     */
    func getBy(soundFontAndPatch: SoundFontAndPatch?) -> LegacyFavorite?

    /**
     Create a new Favorite instance with the given parameters
    
     - parameter soundFontAndPatch: the Patch to associate with
     - parameter keyboardLowestNote: the lowest note of the keyboard
     */
    func add(name: String, soundFontAndPatch: SoundFontAndPatch, keyboardLowestNote: Note?)

    /**
     Begin editing a Favorite

     - parameter config: the configuration to apply to the editor
     - parameter view: the UIView which started the editing
     */
    func beginEdit(config: FavoriteEditor.Config)

    /**
     Update the collection due to a change in the given Favorite

     - parameter index: the location where the Favorite should be
     - parameter with: the Favorite instance to use
     */
    func update(index: Int, with: LegacyFavorite)

    /**
     Move a Favorite from one place in the collection to another.

     - parameter from: where the Favorite is coming from
     - parameter to: where the Favorite is moving to
     */
    func move(from: Int, to: Int)

    /**
     The Favorite at the given index is selected by the user.

     - parameter index: the index that is selected
     */
    func selected(index: Int)

    /**
     Remove the Favorite at the given index.

     - parameter index: the index to remove
     - parameter bySwiping: true if the removing was done via the user
     */
    func remove(index: Int, bySwiping: Bool)

    /**
     Remove all Favorite instances associated with the given SoundFont.

     - parameter associatedWith: the SoundFont to look for
     */
    func removeAll(associatedWith: SoundFont)

    /**
     Obtain a count of the number of Favorite instances associated with the given SoundFont.

     - parameter associatedWith: what to look for
     - returns: count
     */
    func count(associatedWith: SoundFont) -> Int

    /**
     Subscribe to notifications when the collection changes. The types of changes are defined in FavoritesEvent enum.

     - parameter subscriber: the object doing the monitoring
     - parameter notifier: the closure to invoke when a change takes place
     - returns: token that can be used to unsubscribe
     */
    @discardableResult
    func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (FavoritesEvent) -> Void) -> SubscriberToken
}
