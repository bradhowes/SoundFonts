// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

enum FavoriteChangeKind {
    case added(Favorite)
    case selected(Favorite)
    case changed(Favorite)
    case removed(Favorite, bySwiping: Bool)
}

/**
 Manages the collection of Favorite patch settings
 */
protocol FavoritesManager: class, SwipingActivity {

    typealias Notifier<O: AnyObject> = (FavoriteChangeKind) -> Void

    /**
     Determine if the given Patch instance is associated with a Favorite instance
    
     - parameter patch: the Patch to look for
     - returns: true if it is associated with a Favorite instance
     */
    func isFavored(patch: Patch) -> Bool

    /**
     Create a new Favorite instance with the given parameters
    
     - parameter patch: the Patch to associate with
     - parameter keyboardLowestNote: the lowest note of the keyboard
     */
    func add(patch: Patch, keyboardLowestNote: Note)

    func edit(favorite: Favorite, sender: UIView)

    /**
     Remove a previous patch associaed with the given Patch

     - parameter patch: the Patch to remove
     */
    func remove(patch: Patch, bySwiping: Bool)

    func removeAll(associatedWith: SoundFont)

    func count(associatedWith: SoundFont) -> Int

    /**
     Install a closure to be called when a Favorite change happens. The closure takes three arguments: the observer
     object that was registered to receive notifications, an enum indicating the kind of change that took place, and
     the Favorite instance the change affected.
     
     - parameter closure: the closure to install
     - returns: unique identifier that can be used to remove the notifier via `removeNotifier`
     */
    @discardableResult
    func addFavoriteChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken

    /**
     Remove an existing notifier.
     
     - parameter key: the key associated with the notifier and returned by `addFavoriteChangeNotifier`
     */
    func removeNotifier(forKey key: UUID)
}
