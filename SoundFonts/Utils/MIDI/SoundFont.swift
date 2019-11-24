// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit
import GameKit

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public class SoundFont: Codable {

    /// Extension for all SoundFont files in the application bundle
    public static let soundFontExtension = "sf2"

    /// Presentation name of the sound font
    public let displayName: String

    /// The file name of the sound font (sans extension)
    public let fileName: String

    /// Width of the sound font name
    public lazy var nameWidth = displayName.systemFontWidth

    ///  The resolved URL for the sound font
    public lazy var fileURL: URL = FileManager.default.localDocumentsDirectory
        .appendingPathComponent(fileName, isDirectory: false)

    /// The collection of Patches found in the sound font
    public let patches: [Patch]

    enum CodingKeys: String, CodingKey {
        case displayName
        case fileName
        case patches
    }

    public init(_ soundFontInfo: SoundFontInfo) {
        let name = soundFontInfo.name
        self.displayName = name
        self.fileName = name + "." + Self.soundFontExtension
        self.patches = soundFontInfo.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0, name) }
    }
}

extension SoundFont {

    /**
     Locate a patch in the SoundFont using a display name.

     - parameter name: the display name to search for

     - returns: found Patch or nil
     */
    public func findPatch(_ name: String) -> Patch? {
        guard let found = findPatchIndex(name) else { return nil }
        return patches[found]
    }

    /**
     Obtain the index to a Patch with a given name.
     
     - parameter name: the display name to search for
     
     - returns: index of found object or nil if not found
     */
    public func findPatchIndex(_ name: String) -> Int? {
        return patches.firstIndex(where: { return $0.name == name })
    }
}

extension SoundFont: Hashable {

    public func hash(into hasher: inout Hasher) { hasher.combine(fileName) }

    public static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.fileName == rhs.fileName }
}

extension SoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
