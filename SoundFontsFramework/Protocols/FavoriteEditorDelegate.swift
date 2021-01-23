// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Reason why the FavoriteDetailController view was dismissed by the user.
 */
public enum FavoriteEditorDismissedReason {
    case done(response: FavoriteEditor.Response)
    case cancel
}

/**
 Protocol for the `FavoriteDetailController` delegate instance.
 */
public protocol FavoriteEditorDelegate: NSObjectProtocol {

    /**
     Notification when the FavoriteDetailController is dismissed and editing of a particular Favorite instance
     is over.
    
     - parameter index: the index of the Favorite that was being edited
     - parameter reason: the reason for the dismissal
     */
    func dismissed(_ index: IndexPath, reason: FavoriteEditorDismissedReason)
}
