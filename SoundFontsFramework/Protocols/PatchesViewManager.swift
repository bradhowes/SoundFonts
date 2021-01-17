// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Defines the available actions of a PatchesViewManager.
 */
public protocol PatchesViewManager: UpperViewSwipingActivity {

    /**
     Dismiss the search keyboard.
     */
    func dismissSearchKeyboard()

    func addSoundFonts(urls: [URL])
}
