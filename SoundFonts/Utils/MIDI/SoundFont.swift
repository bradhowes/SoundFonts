// Copyright (c) 2016 Brad Howes. All rights reserved.

import UIKit
import GameKit

/**
 Representation of a sound font library. NOTE: all sound font files must have 'sf2' extension.
 */
public class SoundFont: Codable {

    /// Extension for all SoundFont files in the application bundle
    public static let soundFontExtension = "sf2"

    enum Kind: Codable, Hashable {

        case builtin(resource: URL)
        case installed(fileName: String)

        init(from decoder: Decoder) throws {
            var container = try! decoder.unkeyedContainer()
            let kind = try! container.decode(Int.self)
            let value = try! container.decode(String.self)
            switch kind {
            case 0:
                let url = URL(fileURLWithPath: value)
                let name = url.lastPathComponent.split(separator: ".")[0]
                guard let path = Bundle(for: SoundFont.self)
                    .path(forResource: String(name), ofType: SoundFont.soundFontExtension) else {
                        fatalError()
                }
                self = .builtin(resource: URL(fileURLWithPath: path))
            case 1:
                self = .installed(fileName: value)
            default:
                fatalError()
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            switch self {
            case .builtin(let resource):
                try! container.encode(0)
                try! container.encode(resource.lastPathComponent)
            case .installed(let fileName):
                try! container.encode(1)
                try! container.encode(fileName)
            }
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .builtin(let resource): hasher.combine(resource.path)
            case .installed(let fileName): hasher.combine(fileName)
            }
        }

        public static func == (lhs: Kind, rhs: Kind) -> Bool { lhs.hashValue == rhs.hashValue }

        var fileURL: URL {
            switch self {
            case .builtin(let resource):
                return resource
            case .installed(let fileName):
                return FileManager.default.localDocumentsDirectory.appendingPathComponent(fileName)
            }
        }
    }

    /// Presentation name of the sound font
    public let displayName: String

    private let kind: Kind

    /// Width of the sound font name
    public lazy var nameWidth = displayName.systemFontWidth

    ///  The resolved URL for the sound font
    public var fileURL: URL { kind.fileURL }

    /// The collection of Patches found in the sound font
    public let patches: [Patch]

    enum CodingKeys: String, CodingKey {
        case displayName
        case kind
        case patches
    }

    public init(_ soundFontInfo: SoundFontInfo) {
        let name = soundFontInfo.name
        let uuid = UUID()
        self.displayName = name
        self.kind = .installed(fileName:name + "_" + uuid.uuidString + "." + Self.soundFontExtension)
        self.patches = soundFontInfo.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0, name) }
    }

    public init(_ name: String, resource: URL, info: SoundFontInfo) {
        let name = name
        self.displayName = name
        self.kind = .builtin(resource: resource)
        self.patches = info.patches.enumerated().map { Patch($0.1.name, $0.1.bank, $0.1.patch, $0.0, name) }
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

    public func hash(into hasher: inout Hasher) { hasher.combine(kind) }

    public static func == (lhs: SoundFont, rhs: SoundFont) -> Bool { lhs.kind == rhs.kind }
}

extension SoundFont: CustomStringConvertible {

    public var description: String { "[SoundFont '\(displayName)']" }
}
