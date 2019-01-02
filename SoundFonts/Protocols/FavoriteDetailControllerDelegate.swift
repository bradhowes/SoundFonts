//
//  FavoriteDetailControllerDelegate.swift
//  SoundFonts
//
//  Created by Brad Howes on 1/1/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import UIKit

/**
 Reason why the FavoriteDetailController view was dismissed by the user.
 */
enum FavoriteDetailControllerDismissedReason {
    case cancel, done
}

/**
 Protocol for the `FavoriteDetailController` delegate instance.
 */
protocol FavoriteDetailControllerDelegate : NSObjectProtocol {
    /**
     Notification when the FavoriteDetailController is dismissed and editing of a particular Favorite instance
     is over.
    
     - parameter index: the index of the Favorite that was being edited
     - parameter reason: the reason for the dismisal
     */
    func dismissed(_ index: IndexPath, reason: FavoriteDetailControllerDismissedReason)
}
