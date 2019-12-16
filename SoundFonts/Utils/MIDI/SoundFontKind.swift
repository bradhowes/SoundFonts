// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

enum SoundFontKindError: Error {
    case invalidKind
}

/**
 There are two types of SoundFont instances in the application: a built-in kind that resides in the app's bundle, and
 a file kind which comes from an external source.
 */
enum SoundFontKind {

    case builtin(resource: URL)
    case installed(fileName: String)

    /// The URL that points to the data file that defnes the SoundFont.
    var fileURL: URL {
        switch self {
        case .builtin(let resource): return resource
        case .installed(let name): return FileManager.default.localDocumentsDirectory.appendingPathComponent(name)
        }
    }

    /// The String representation of the fileURL
    var path: String { return fileURL.path }

    /// True if the resoure can be deleted by the user
    var removable: Bool {
        switch self {
        case .builtin(resource: _): return false
        case .installed(fileName: _): return true
        }
    }

    /// Key used to encode/decode the above case types.
    private enum InternalKey: Int {
        case builtin = 0
        case installed = 1
    }
}

// MARK: - Codable Protocol

extension SoundFontKind: Codable {

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let kind = InternalKey(rawValue: try container.decode(Int.self))
        let value = try container.decode(String.self)
        switch kind {
        case .builtin:
            let url = URL(fileURLWithPath: value)
            let name = url.deletingPathExtension().lastPathComponent
            guard let path = Bundle.main.path(forResource: name, ofType: SoundFont.soundFontExtension) else {
                fatalError()
            }
            self = .builtin(resource: URL(fileURLWithPath: path))
        case .installed:
            self = .installed(fileName: value)
        default:
            throw SoundFontKindError.invalidKind
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        switch self {
        case .builtin(let resource):
            try container.encode(InternalKey.builtin.rawValue)
            try container.encode(resource.lastPathComponent)
        case .installed(let fileName):
            try container.encode(InternalKey.installed.rawValue)
            try container.encode(fileName)
        }
    }
}

// MARK: - Hashable Protocol

extension SoundFontKind: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .builtin(let resource):
            hasher.combine(InternalKey.builtin.rawValue)
            hasher.combine(resource.lastPathComponent)
        case .installed(let fileName):
            hasher.combine(InternalKey.installed.rawValue)
            hasher.combine(fileName)
        }
    }
}
