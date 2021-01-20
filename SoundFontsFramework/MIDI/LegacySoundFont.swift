// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import os
import SoundFontInfoLib
import SF2Files

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public final class LegacySoundFont: Codable {
    private static let logger = Logging.logger("SFont")

    /// Presentation name of the sound font
    var displayName: String

    ///  The resolved URL for the sound font
    public var fileURL: URL { kind.fileURL }

    /// True if the SF2 file is not part of the install
    var removable: Bool { kind.removable }

    public typealias Key = UUID
    let key: Key

    let originalDisplayName: String

    @DecodableDefault.EmptyString var embeddedName: String
    @DecodableDefault.EmptyString var embeddedComment: String
    @DecodableDefault.EmptyString var embeddedAuthor: String
    @DecodableDefault.EmptyString var embeddedCopyright: String

    let kind: SoundFontKind

    /// The collection of Patches found in the sound font
    let patches: [LegacyPatch]

    /// Collection of tags assigned to the sound font
    @DecodableDefault.EmptyTagSet var tags: Set<LegacyTag.Key>

    /**
     Constructor for installed sound font files -- those added via File app.

     - parameter displayName: the display name of the resource
     - parameter soundFontInfo: patch info from the sound font
     - parameter key: UUID for this font
     */
    public init(_ displayName: String, soundFontInfo: SoundFontInfo, url: URL, key: Key) {
        self.key = key
        self.displayName = displayName
        self.originalDisplayName = displayName
        self.embeddedName = soundFontInfo.embeddedName
        self.embeddedComment = soundFontInfo.embeddedComment
        self.embeddedAuthor = soundFontInfo.embeddedAuthor
        self.embeddedCopyright = soundFontInfo.embeddedCopyright
        self.kind = Settings.shared.copyFilesWhenAdding ?
            .installed(fileName: displayName + "_" + key.uuidString + SF2Files.sf2DottedExtension) :
            .reference(bookmark: Bookmark(url: url, name: displayName))
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
        self.embeddedComment = soundFontInfo.embeddedComment
        self.embeddedAuthor = soundFontInfo.embeddedAuthor.isEmpty ? "Unknown" : soundFontInfo.embeddedAuthor
        self.embeddedCopyright = soundFontInfo.embeddedCopyright.isEmpty ? "Unknown" : soundFontInfo.embeddedCopyright
        self.kind = .builtin(resource: resource)
        self.patches = Self.makePatches(soundFontInfo.presets)
    }
}

extension LegacySoundFont {

    public static func makeSoundFont(from url: URL) -> Result<LegacySoundFont, SoundFontFileLoadFailure> {
        os_log(.info, log: Self.logger, "makeSoundFont - '%{public}s'", url.lastPathComponent)

        guard let info = SoundFontInfo.load(viaParser: url) else {
            os_log(.error, log: Self.logger, "failed to process SF2 file")
            return .failure(.invalidSoundFont(url.lastPathComponent))
        }

        guard !info.presets.isEmpty else {
            os_log(.error, log: Self.logger, "failed to locate any presets")
            return .failure(.invalidSoundFont(url.lastPathComponent))
        }

        let (fileName, uuid) = url.lastPathComponent.stripEmbeddedUUID()

        // Strip off the extension to make a display name. We set the embedded name if it is empty, but we do not use
        // the embedded name as it is often garbage. We do show it in the SoundFont editor sheet.
        let displayName = String(fileName[fileName.startIndex..<(fileName.lastIndex(of: ".") ?? fileName.endIndex)])
        if info.embeddedName.isEmpty {
            info.embeddedName = displayName
        }

        let soundFont = LegacySoundFont(displayName, soundFontInfo: info, url: url, key: uuid ?? Key())
        if Settings.shared.copyFilesWhenAdding {
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
        os_log(.info, log: Self.logger, "SF2 source: '%{public}s'", source.absoluteString)
        os_log(.info, log: Self.logger, "SF2 destination: '%{public}s'", destination.absoluteString)
        let secured = source.startAccessingSecurityScopedResource()
        defer { if secured { source.stopAccessingSecurityScopedResource() } }
        try FileManager.default.copyItem(at: source, to: destination)
    }

    private static func makePatches(_ patches: [SoundFontInfoPreset]) -> [LegacyPatch] {
        patches.enumerated().map { LegacyPatch($0.1.name, Int($0.1.bank), Int($0.1.preset), $0.0) }
    }
}

extension LegacySoundFont {

    /// Determines if the sound font file exists on the device
    public var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

    public func makeSoundFontAndPatch(at index: Int) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFontKey: self.key, patchIndex: index)
    }

    public func makeSoundFontAndPatch(for patch: LegacyPatch) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFontKey: self.key, patchIndex: patch.soundFontIndex)
    }

    public func reloadEmbeddedInfo() -> Bool {
        guard let info = SoundFontInfo.load(viaParser: self.fileURL) else { return false }
        embeddedComment = info.embeddedComment
        embeddedAuthor = info.embeddedAuthor.isEmpty ? "Unknown" : info.embeddedAuthor
        embeddedCopyright = info.embeddedCopyright.isEmpty ? "Unknown" : info.embeddedCopyright
        return true
    }
}

extension LegacySoundFont: Hashable {

    public func hash(into hasher: inout Hasher) { hasher.combine(key) }

    public static func == (lhs: LegacySoundFont, rhs: LegacySoundFont) -> Bool { lhs.key == rhs.key }
}

extension LegacySoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
