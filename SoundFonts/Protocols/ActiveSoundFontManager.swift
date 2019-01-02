//
//  ActiveSoundFontManagement.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/30/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation

/**
 Maintains the indices of the selected and active SoundFont. Here `index` refers to the in the range
 `[0..SoundFont.keys.count)`. Presentation views must translate into valid IndexPath values.
 */
protocol ActiveSoundFontManager: class {
    /// The index of the currently selected SoundFont
    var selectedIndex: Int { get set }
    /// The index of the currently active SoundFont.
    var activeIndex: Int { get set }
}
