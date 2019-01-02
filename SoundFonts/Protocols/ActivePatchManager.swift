//
//  ActivePatchManagement.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/30/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation

/**
 Maintains the active SoundFont patch being used for sound generation.
 */
protocol ActivePatchManager: class {
    /// The collection of patches currently available for the active SoundFont
    var patches: [Patch] { get }
    /// The currently active patch
    var activePatch: Patch { get set }

    /**
     Install a closure to be called when the active patch changes value.
    
     - parameter notifier: the closure to install
     */
    func addPatchChangeNotifier(_ notifier: @escaping (Patch)->Void)
}
