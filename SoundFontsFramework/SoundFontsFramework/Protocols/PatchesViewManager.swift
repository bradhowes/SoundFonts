// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Defines the available actions of a PatchesViewManager which contains both the list of installed sound fonts on the
 left and on the right the list of presets found in the selected sound font.
 */
public protocol PatchesViewManager: UpperViewSwipingActivity {

    /**
     Dismiss the search keyboard.
     */
    func dismissSearchKeyboard()

    /**
     Add one or more sound fonts to the app via URLs.

     - parameter urls: collection of URLs to add
     */
    func addSoundFonts(urls: [URL])
}
