// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

private let systemFontAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]

extension String {

    /// Obtain the width of a string in the system font
    var systemFontWidth: CGFloat { return (self as NSString).size(withAttributes: systemFontAttributes).width }
}

/// NSCoder setting keys
extension String {

    // Favorite keys
    static let name = "name"
    static let patch = "patch"
    static let lowestNote = "lowestNote"
    static let gain = "gain"
    static let pan = "pan"

    // Patch keys
    static let soundFontName = "soundFontName"
    static let soundFontFileName = "soundFontFileName"
    static let soundFontPatches = "soundFontPatches"

    static let patchName = "patchName"
    static let patchBank = "patchBank"
    static let patchPatch = "patchPatch"
    static let patchIndex = "patchIndex"
}
