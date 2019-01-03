//
//  FavoritesManagement.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/30/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation

enum FavoriteChangeKind {
    case added
    case selected
    case changed
    case removed
}

/**
 Manages the collection of Favorite patch settings
 */
protocol FavoritesManager: class {
    
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

    /**
     Remove a previous patch associaed with the given Patch

     - parameter patch: the Patch to remove
     */
    func remove(patch: Patch)

    /**
     Install a closure to be called when a Favorite change happens. The closure takes two arguments: a enum indicating
     the kind of change that took place, and the Favorite instance the change affected.
     
     - parameter closure: the closure to install
     - returns: unique identifier that can be used to remove the notifier via `removeNotifier`
     */
    @discardableResult
    func addFavoriteChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping (O, FavoriteChangeKind, Favorite) -> Void) -> NotifierToken

    /**
     Remove an existing notifier.
     
     - parameter key: the key associated with the notifier and returned by `addFavoriteChangeNotifier`
     */
    func removeNotifier(forKey key: UUID)
}
