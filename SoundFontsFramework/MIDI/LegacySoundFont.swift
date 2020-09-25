// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public final class LegacySoundFont: Codable {
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
    public let patches: [LegacyPatch]

    public static func makeSoundFont(from url: URL, saveToDisk: Bool) -> Result<LegacySoundFont, SoundFontFileLoadFailure> {
        os_log(.info, log: Self.logger, "makeSoundFont - '%s'", url.lastPathComponent)

        guard let info = SoundFontInfo.load(url) else {
            os_log(.error, log: Self.logger, "failed to fetch content")
            return .failure(.invalidSoundFont(url.lastPathComponent))
        }

        guard !info.presets.isEmpty else {
            os_log(.error, log: Self.logger, "failed to parse content")
            return .failure(.invalidSoundFont(url.lastPathComponent))
        }

        let (fileName, uuid) = url.lastPathComponent.stripEmbeddedUUID()

        // Strip off the extension to make a display name. We set the embedded name if it is empty, but we do not use
        // the embedded name as it is often garbage. We do show it in the SoundFont editor sheet.
        let displayName = String(fileName[fileName.startIndex..<(fileName.lastIndex(of: ".") ?? fileName.endIndex)])
        if info.embeddedName.isEmpty {
            info.embeddedName = displayName
        }

        let soundFont = LegacySoundFont(displayName, soundFontInfo: info, file: url, key: uuid ?? Key())
        if saveToDisk {
            do {
                try copyToAppFolder(source: url, destination: soundFont.fileURL)
            } catch {
                os_log(.error, log: Self.logger, "failed to create file")
                return .failure(.unableToCreateFile(url.lastPathComponent))
            }
        }

        return .success(soundFont)
    }

    private static func copyToAppFolder(source: URL, destination: URL) throws {
        os_log(.info, log: Self.logger, "SF2 source: '%s'", source.absoluteString)
        os_log(.info, log: Self.logger, "SF2 destination: '%s'", destination.absoluteString)
        let secured = source.startAccessingSecurityScopedResource()
        defer { if secured { source.stopAccessingSecurityScopedResource() } }
        try FileManager.default.copyItem(at: source, to: destination)
    }

    /**
     Constructor for installed sound font files -- those added fia File app.

     - parameter displayName: the display name of the resource
     - parameter soundFontInfo: patch info from the sound font
     */
    public init(_ displayName: String, soundFontInfo: SoundFontInfo, file: URL, key: Key) {
        self.key = key
        self.displayName = displayName
        self.originalDisplayName = displayName
        self.embeddedName = soundFontInfo.embeddedName
        self.kind = .installed(fileName:displayName + "_" + key.uuidString + "." + Self.soundFontExtension)
        self.patches = Self.makePatches(soundFontInfo.presets)
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
        self.patches = Self.makePatches(soundFontInfo.presets)
    }

    private static func makePatches(_ patches: [SoundFontInfoPreset]) -> [LegacyPatch] {
        patches.enumerated().map { LegacyPatch($0.1.name, Int($0.1.bank), Int($0.1.preset), $0.0) }
    }
}

extension LegacySoundFont {

    /// Determines if the sound font file exists on the device
    public var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

    public func makeSoundFontAndPatch(for patchIndex: Int) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFontKey: self.key, patchIndex: patchIndex)
    }
}

extension LegacySoundFont: Hashable {

    public func hash(into hasher: inout Hasher) { hasher.combine(key) }

    public static func == (lhs: LegacySoundFont, rhs: LegacySoundFont) -> Bool { lhs.key == rhs.key }
}

extension LegacySoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
