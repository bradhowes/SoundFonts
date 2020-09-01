// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public final class SoundFont: Codable {
    private static let logger = Logging.logger("SFont")

    /// Extension for all SoundFont files in the application bundle
    public static let soundFontExtension = "sf2"

    public static let soundFontDottedExtension = "." + soundFontExtension

    /// Presentation name of the sound font
    public var displayName: String

    /// Width of the sound font name
    // var nameWidth: CGFloat { displayName.systemFontWidth }

    ///  The resolved URL for the sound font
    public var fileURL: URL { kind.fileURL }

    /// True if the SF2 file is not part of the install
    public var removable: Bool { kind.removable }

    public typealias Key = UUID
    public let key: Key

    public let originalDisplayName: String

    public let embeddedName: String

    public let kind: SoundFontKind

    /// The collection of Patches found in the sound font
    public let patches: [Patch]

    public enum Failure: Error {
        case emptyFile
        case invalidSoundFont
        case unableToCreateFile
    }

    public static func makeSoundFont(from url: URL, saveToDisk: Bool) -> Result<SoundFont, Failure> {
        os_log(.info, log: Self.logger, "makeSoundFont - '%s'", url.lastPathComponent)

        let displayName = url.deletingPathExtension().lastPathComponent

        guard let info = SoundFontInfo.load(url) else {
            os_log(.error, log: Self.logger, "failed to fetch content")
            return .failure(.invalidSoundFont)
        }

        guard !info.patches.isEmpty else {
            os_log(.error, log: Self.logger, "failed to parse content")
            return .failure(.invalidSoundFont)
        }

        if info.embeddedName.isEmpty {
            info.embeddedName = displayName
        }

        let soundFont = SoundFont(displayName, embeddedName: info.embeddedName, patches: info.patches)
        if saveToDisk {
            let path = soundFont.fileURL
            os_log(.info, log: Self.logger, "creating SF2 file at '%s'", path.lastPathComponent)
            guard FileManager.default.createFile(atPath: path.path, contents: info.contents, attributes: nil) else {
                os_log(.error, log: Self.logger, "failed to create file")
                return .failure(.unableToCreateFile)
            }
        }

        return .success(soundFont)
    }

    /**
     Constructor for installed sound font files -- those added fia File app.

     - parameter displayName: the display name of the resource
     - parameter soundFontInfo: patch info from the sound font
     */
    public init(_ displayName: String, embeddedName: String, patches: [SoundFontInfoPatch]) {
        let key = Key()
        self.key = key
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.originalDisplayName = self.displayName
        self.embeddedName = embeddedName
        self.kind = .installed(fileName:displayName + "_" + key.uuidString + "." + Self.soundFontExtension)
        self.patches = Self.makePatches(patches)
    }

    /**
     Constructor for built-in sound font files -- those in the Bundle.

     - parameter displayName: the display name of the resource
     - parameter soundFontInfo: patch info from the sound font
     - parameter resource: the name of the resource in the bundle
     */
    public init(_ displayName: String, soundFontInfo: SoundFontInfo, resource: URL) {
        self.key = Key()
        self.displayName = displayName
        self.originalDisplayName = displayName
        self.embeddedName = soundFontInfo.embeddedName
        self.kind = .builtin(resource: resource)
        self.patches = Self.makePatches(soundFontInfo.patches)
    }

    private static func makePatches(_ patches: [SoundFontInfoPatch]) -> [Patch] {
        patches.enumerated().map { Patch($0.1.name, Int($0.1.bank), Int($0.1.patch), $0.0) }
    }
}

extension SoundFont {

    /// Determines if the sound font file exists on the device
    public var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

    public func makeSoundFontAndPatch(for patchIndex: Int) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFont: self, patchIndex: patchIndex)
    }
}

extension SoundFont: Hashable {

    public func hash(into hasher: inout Hasher) { hasher.combine(key) }

    public static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.key == rhs.key }
}

extension SoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
