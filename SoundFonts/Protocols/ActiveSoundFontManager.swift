// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

/**
 Maintains the indices of the selected and active SoundFont. Here `index` refers to the in the range
 `[0..SoundFont.keys.count)`. Presentation views must translate these into valid IndexPath values.
 */
protocol ActiveSoundFontManager: class {

    var selectedSoundFont: SoundFont? { get set }

    var activeSoundFont: SoundFont? { get }
}
