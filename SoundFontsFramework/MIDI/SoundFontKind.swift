// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os
import SF2Files

public enum SoundFontKindError: Error {
    case invalidKind
}

/**
 There are two types of SoundFont instances in the application: a built-in kind that resides in the app's bundle, and
 a file kind which comes from an external source.
 */
public enum SoundFontKind {
    static let log = Logging.logger("SFKind")

    case builtin(resource: URL)
    case installed(fileName: String)
    case reference(bookmark: Bookmark)

    /// The URL that points to the data file that defnes the SoundFont.
    public var fileURL: URL {
        switch self {
        case .builtin(let resource): return resource
        case .installed(let fileName): return FileManager.default.sharedDocumentsDirectory.appendingPathComponent(fileName)
        case .reference(let bookmark): return bookmark.url
        }
    }

    /// The String representation of the fileURL
    public var path: String { return fileURL.path }

    /// True if the file deleted by the user
    public var removable: Bool {
        switch self {
        case .builtin: return false
        case .installed: return true
        case .reference: return true
        }
    }

    /// True if is resource
    public var resource: Bool {
        switch self {
        case .builtin: return true
        case .installed: return false
        case .reference: return false
        }
    }

    /// Key used to encode/decode the above case types.
    private enum InternalKey: Int {
        case builtin = 0
        case installed = 1
        case reference = 2
    }
}

// MARK: - Codable Protocol

extension SoundFontKind: Codable {

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let kind = InternalKey(rawValue: try container.decode(Int.self))
        let value = try container.decode(String.self)
        switch kind {
        case .builtin:
            let name = URL(fileURLWithPath: value).deletingPathExtension().lastPathComponent
            let url = SF2Files.resource(name: name)
            self = .builtin(resource: url)
        case .installed:
            self = .installed(fileName: value)
        default:
            throw SoundFontKindError.invalidKind
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .builtin(let resource):
            try container.encode(InternalKey.builtin.rawValue)
            try container.encode(resource.lastPathComponent)
        case .installed(let fileName):
            try container.encode(InternalKey.installed.rawValue)
            try container.encode(fileName)
        case .reference(let bookmark):
            try container.encode(InternalKey.reference.rawValue)
            try container.encode(bookmark)
        }
    }
}

// MARK: - Hashable Protocol

extension SoundFontKind: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .builtin(let resource):
            hasher.combine(InternalKey.builtin.rawValue)
            hasher.combine(resource.lastPathComponent)
        case .installed(let fileName):
            hasher.combine(InternalKey.installed.rawValue)
            hasher.combine(fileName)
        case .reference(let bookmark):
            hasher.combine(InternalKey.reference.rawValue)
            hasher.combine(bookmark)
        }
    }
}
