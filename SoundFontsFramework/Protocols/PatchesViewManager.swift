// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Defines the available actions that can be asked of a PatchesViewManager.
 */
public protocol PatchesViewManager: UpperViewSwipingActivity {

    /**
     Dismiss the search keyboard.
     */
    func dismissSearchKeyboard()

    func addSoundFonts(urls: [URL])
}
