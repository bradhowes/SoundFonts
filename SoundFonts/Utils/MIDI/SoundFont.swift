// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit
import GameKit
import os

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public final class SoundFont: Codable {
    private static let logger = Logging.logger("SFont")

    /// Extension for all SoundFont files in the application bundle
    public static let soundFontExtension = "sf2"

    /// Presentation name of the sound font
    public var displayName: String

    /// Width of the sound font name
    public var nameWidth: CGFloat { displayName.systemFontWidth }

    ///  The resolved URL for the sound font
    public var fileURL: URL { kind.fileURL }

    public let uuid: UUID

    public let originalDisplayName: String

    /// The collection of Patches found in the sound font
    public private(set) var patches: [Patch]

    private let kind: SoundFontKind

    public static func generateSoundFont(from url: URL) -> SoundFont? {
        os_log(.info, log: Self.logger, "generateSoundFont - '%s'", url.lastPathComponent)

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

        let soundFont = SoundFont(info)
        os_log(.info, log: Self.logger, "creating SF2 file at '%s'", soundFont.fileURL.lastPathComponent)
        let result = FileManager.default.createFile(atPath: soundFont.fileURL.path, contents: data, attributes: nil)
        os_log(.info, log: Self.logger, "created - %s", result ? "true" : "false")

        return result ? soundFont : nil
    }

    /**
     Constructor for installed sound font files -- those added fia File app.

     - parameter info: patch info from the sound font and its display name.
     */
    public init(_ soundFontInfo: SoundFontInfo) {
        let name = soundFontInfo.name
        let uuid = UUID()
        self.uuid = uuid
        self.displayName = name
        self.originalDisplayName = name
        self.kind = .installed(fileName:name + "_" + uuid.uuidString + "." + Self.soundFontExtension)
        self.patches = soundFontInfo.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0, uuid) }
    }

    /**
     Constructor for built-in sound font files -- those in the Bundle.

     - parameter name: the display name of the resource
     - parameter resource: the name of the resource in the bundle
     - parameter info: patch info from the sound font
     */
    public init(_ name: String, resource: URL, soundFontInfo: SoundFontInfo) {
        let name = name
        let uuid = UUID()
        self.uuid = uuid
        self.displayName = name
        self.originalDisplayName = name
        self.kind = .builtin(resource: resource)
        self.patches = soundFontInfo.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0, uuid) }
    }
}

extension SoundFont {

    /// Determines if the sound font file exists on the device
    var isAvailable: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

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

    public func hash(into hasher: inout Hasher) { hasher.combine(kind) }

    public static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.kind == rhs.kind }
}

extension SoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
