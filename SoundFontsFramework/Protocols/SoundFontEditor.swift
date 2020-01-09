// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public protocol FontEditorActionGenerator {

    func createEditSwipeAction(at cell: FontCell, with soundFont: SoundFont) -> UIContextualAction
    func createDeleteSwipeAction(at cell: FontCell, with soundFont: SoundFont, indexPath: IndexPath)
        -> UIContextualAction
}
