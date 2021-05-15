// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public enum LocalizedStrings {

    static let cancelButton = "Cancel"
    static let saveButton = "Save"

    // Favorite Editor
    static let favoriteEditorTitle = "Favorite"
    static let gain = "Gain"
    static let pan = "Pan"
    static let lowestKey = "Lowest Key"
    static let soundFontNameFormatter = "SoundFont: %s"
    static let originalPatchNameFormatter = "Original: %s"
    static let bankAndProgramFormatter = "Bank: %d Program: %d"

    // Font Editor
    static let fontEditorTitle = "SoundFont"
    static let name = "Name"
    static let originalFontNameFormatter = "Original: %s"
    static let embeddedFontNameFormatter = "Embedded: %s"

    static func presetCount(_ count: Int) -> String { Formatters.format(presetCount: count) }
    static func favoriteCount(_ count: Int) -> String { Formatters.format(favoriteCount: count) }

    // Settings Editor
    static let done = "Done"
    static let settingsEditorTitle = "Settings"
    static let showSolfegeTags = "Show solfège tags"
    static let playNoteOnPatchSelect = "Play note on patch select"
    static let showKeyLabels = "Show key labels"
    static let keyWidth = "Key Width"
    static let removeDefaultSoundFonts = "Remove default soundfonts"
    static let remove = "Remove"
    static let restoreDefaultSoundFonts = "Restore default soundfonts"
    static let restore = "Restore"

    // Remove/Restore Alert
    static let removed = "Removed entriies to the built-in sound fonts."
    static let restored = "Restored entriies to the built-in sound fonts."
    static let ok = "OK"
}
