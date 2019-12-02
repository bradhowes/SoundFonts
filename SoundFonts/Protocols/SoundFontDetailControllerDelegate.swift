// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Reason why the SoundFontDetailController view was dismissed by the user.
 */
enum SoundFontDetailControllerDismissedReason {
    case cancel
    case done(indexPath: IndexPath, soundFont: SoundFont)
    case delete(indexPath: IndexPath, soundFont: SoundFont)
}

/**
 Protocol for the `SoundFontDetailController` delegate instance.
 */
protocol SoundFontDetailControllerDelegate : NSObjectProtocol {
    /**
     Notification when the SoundFontDetailController is dismissed and editing of a particular SoundFont instance
     is over.
    
     - parameter reason: the reason for the dismisal
     */
    func dismissed(reason: SoundFontDetailControllerDismissedReason)
}
