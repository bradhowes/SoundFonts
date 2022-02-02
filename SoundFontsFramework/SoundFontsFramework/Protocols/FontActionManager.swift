// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/// Handles actions on SoundFont instances.
public protocol FontActionManager {

  /**
   Obtain a swipe action that will edit a SoundFont instance.

   - parameter cell: the table cell to attach to
   - parameter soundFont: the SoundFont instance that will be edited
   - returns: new swipe action
   */
  func createEditSwipeAction(at: IndexPath, cell: TableCell, soundFont: SoundFont) -> UIContextualAction

  /**
   Obtain a swipe action that will delete a SoundFont instance.

   - parameter view: the table cell to attach to
   - parameter soundFont: the SoundFont instance that will be edited
   - parameter indexPath: location of the cell to be deleted
   - returns: new swipe action
   */
  func createDeleteSwipeAction(at: IndexPath, cell: TableCell, soundFont: SoundFont) -> UIContextualAction

  /**
   Begin editing the given font.

   - parameter indexPath: location of the cell to be deleted
   - parameter cell: the table cell to attach to
   - parameter soundFont: the SoundFont instance that will be edited
   - parameter completionHandler: the closure to run when editing is done. Sole parameter is `true` if changes were
   accepted, `false` if cancelled.
   */
  func beginEditingFont(at: IndexPath, cell: TableCell, soundFont: SoundFont, completionHandler: ((Bool) -> Void)?)
}
