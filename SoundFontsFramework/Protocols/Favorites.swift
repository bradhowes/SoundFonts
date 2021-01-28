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
    case removedAll(associatedWith: LegacySoundFont)
    case restored

    var favorite: LegacyFavorite? {
        switch self {
        case let .added(index: _, favorite: favorite): return favorite
        case let .changed(index: _, favorite: favorite): return favorite
        case let .removed(index: _, favorite: favorite, bySwiping: _): return favorite
        default: return nil
        }
    }
}

/**
 Actions available on a collection of Favorite instances. Supports subscribing to changes.
 */
public protocol Favorites {

    var restored: Bool { get }

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
    func getBy(soundFontAndPatch: SoundFontAndPatch) -> LegacyFavorite?

    /**
     Add a Favorite to the collection

     - parameter favorite: instance to add
     */
    func add(favorite: LegacyFavorite)

    /**
     Begin editing a Favorite

     - parameter config: the configuration to apply to the editor
     - parameter view: the UIView which started the editing
     */
    func beginEdit(config: FavoriteEditor.Config)

    /**
     Update the collection due to a change in the given Favorite

     - parameter index: the location where the Favorite should be
     - parameter config: the latest config settings
     */
    func update(index: Int, config: PresetConfig)

    /**
     Move a Favorite from one place in the collection to another.

     - parameter from: where the Favorite is coming from
     - parameter to: where the Favorite is moving to
     */
    func move(from: Int, to: Int)

    func setEffects(favorite: LegacyFavorite, delay: DelayConfig?, reverb: ReverbConfig?)

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
    func removeAll(associatedWith: LegacySoundFont)

    /**
     Obtain a count of the number of Favorite instances associated with the given SoundFont.

     - parameter associatedWith: what to look for
     - returns: count
     */
    func count(associatedWith: LegacySoundFont) -> Int

    /**
     Subscribe to notifications when the collection changes. The types of changes are defined in FavoritesEvent enum.

     - parameter subscriber: the object doing the monitoring
     - parameter notifier: the closure to invoke when a change takes place
     - returns: token that can be used to unsubscribe
     */
    @discardableResult
    func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping (FavoritesEvent) -> Void) -> SubscriberToken
}
