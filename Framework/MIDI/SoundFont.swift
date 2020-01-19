// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public final class SoundFont: Codable {
    private static let logger = Logging.logger("SFont")

    /// Extension for all SoundFont files in the application bundle
    public static let soundFontExtension = "sf2"

    public typealias Key = UUID

    /// Presentation name of the sound font
    public var displayName: String

    /// Width of the sound font name
    // var nameWidth: CGFloat { displayName.systemFontWidth }

    ///  The resolved URL for the sound font
    public var fileURL: URL { kind.fileURL }

    public var removable: Bool { kind.removable }

    public let key: Key

    public let originalDisplayName: String

    public let embeddedName: String

    public let kind: SoundFontKind

    /// The collection of Patches found in the sound font
    public let patches: [Patch]

    public static func makeSoundFont(from url: URL, saveToDisk: Bool) -> SoundFont? {
        os_log(.info, log: Self.logger, "makeSoundFont - '%s'", url.lastPathComponent)

        let displayName = url.deletingPathExtension().lastPathComponent

        // If this is a resource from iCloud we need to enable access to it. This will return `false` if the URL is
        // not in a security scope.
        let secured = url.startAccessingSecurityScopedResource()
        let data = try? Data(contentsOf: url, options: .dataReadingMapped)
        if secured { url.stopAccessingSecurityScopedResource() }

        guard let content = data else {
            os_log(.error, log: Self.logger, "failed to fetch content")
            return nil
        }

        var info = GetSoundFontInfo(data: content)
        if info.name.isEmpty {
            info.name = displayName
        }

        if info.patches.isEmpty {
            os_log(.error, log: Self.logger, "failed to parse content")
            return nil
        }

        let soundFont = SoundFont(displayName, soundFontInfo: info)
        if saveToDisk {
            os_log(.info, log: Self.logger, "creating SF2 file at '%s'", soundFont.fileURL.lastPathComponent)
            let result = FileManager.default.createFile(atPath: soundFont.fileURL.path, contents: data, attributes: nil)
            os_log(.info, log: Self.logger, "created - %s", result ? "true" : "false")
            return result ? soundFont : nil
        }

        return soundFont
    }

    /**
     Constructor for installed sound font files -- those added fia File app.

     - parameter displayName: the display name of the resource
     - parameter soundFontInfo: patch info from the sound font
     */
    public init(_ displayName: String, soundFontInfo: SoundFontInfo) {
        let key = Key()
        self.key = key
        self.displayName = displayName
        self.originalDisplayName = displayName
        self.embeddedName = soundFontInfo.name
        self.kind = .installed(fileName:displayName + "_" + key.uuidString + "." + Self.soundFontExtension)
        self.patches = soundFontInfo.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0) }
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
        self.embeddedName = soundFontInfo.name
        self.kind = .builtin(resource: resource)
        self.patches = soundFontInfo.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0) }
    }
}

extension SoundFont {

    /// Determines if the sound font file exists on the device
    public var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

    public func makeSoundFontPatch(for patchIndex: Int) -> SoundFontPatch {
        SoundFontPatch(soundFont: self, patchIndex: patchIndex)
    }
}

extension SoundFont: Hashable {

    public func hash(into hasher: inout Hasher) { hasher.combine(key) }

    public static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.key == rhs.key }
}

extension SoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
