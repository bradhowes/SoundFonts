// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

/**
 Delegate protocol for the Patches view search maanger.
 */
protocol PatchSearchManagerDelegate: class {

    /**
     Notify delegate that the user selected the given Patch index (*not* an IndexPath)
    
     - parameter patchIndex: the Patch index that was selected
     */
    func selected(patch: Patch)
    
    /**
     Ask the delegate to scroll the view to show the search field.
     */
    func scrollToSearchField()

    /**
     Ask the delegate to update the given cell.
    
     - parameter cell: the cell to update
     - parameter with: the Patch to update with
     */
    // func update(cell: PatchCell, with: Patch)
    
    /**
     Ask the delegate to create a Favorite swipe action for the given cell and Patch.
    
     - parameter at: the cell to create for
     - parameter with: the Patch to use in a Favorite
     - returns: new swipe action
     */
    func createLeadingSwipeActions(at: PatchCell, with: Patch) -> UISwipeActionsConfiguration?

    func createTrailingSwipeActions(at: PatchCell, with: Patch) -> UISwipeActionsConfiguration?
}
