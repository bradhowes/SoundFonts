// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
final class SoundFont: Codable {
    private static let logger = Logging.logger("SFont")

    /// Extension for all SoundFont files in the application bundle
    static let soundFontExtension = "sf2"

    typealias Key = UUID

    /// Presentation name of the sound font
    var displayName: String

    /// Width of the sound font name
    // var nameWidth: CGFloat { displayName.systemFontWidth }

    ///  The resolved URL for the sound font
    var fileURL: URL { kind.fileURL }

    var removable: Bool { kind.removable }

    let key: Key

    let originalDisplayName: String

    let embeddedName: String

    let kind: SoundFontKind

    /// The collection of Patches found in the sound font
    let patches: [Patch]

    static func makeSoundFont(from url: URL, saveToDisk: Bool) -> SoundFont? {
        os_log(.info, log: Self.logger, "makeSoundFont - '%s'", url.lastPathComponent)

        // If this is a resource from iCloud we need to enable access to it. This will return `false` if the URL is
        // not in a security scope.
        let secured = url.startAccessingSecurityScopedResource()
        let data = try? Data(contentsOf: url, options: .dataReadingMapped)
        if secured { url.stopAccessingSecurityScopedResource() }

        guard let content = data else {
            os_log(.error, log: Self.logger, "failed to fetch content")
            return nil
        }

        let info = GetSoundFontInfo(data: content)
        if info.name.isEmpty || info.patches.isEmpty {
            os_log(.error, log: Self.logger, "failed to parse content")
            return nil
        }

        let displayName = url.deletingPathExtension().lastPathComponent
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
    init(_ displayName: String, soundFontInfo: SoundFontInfo) {
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
    init(_ displayName: String, soundFontInfo: SoundFontInfo, resource: URL) {
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
    var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

    func makeSoundFontPatch(for patchIndex: Int) -> SoundFontPatch {
        SoundFontPatch(soundFont: self, patchIndex: patchIndex)
    }
}

extension SoundFont: Hashable {

    func hash(into hasher: inout Hasher) { hasher.combine(key) }

    static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.key == rhs.key }
}

extension SoundFont: CustomStringConvertible {

    var description: String { "[SoundFont '\(displayName)']" }
}
