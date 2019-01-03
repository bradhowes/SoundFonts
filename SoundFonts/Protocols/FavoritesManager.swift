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
     Install a closure to be called when the active favorite changes value.
     
     - parameter notifier: the closure to install
     */
    func addFavoriteChangeNotifier(_ notifier: @escaping (FavoriteChangeKind, Favorite)->Void)
}
