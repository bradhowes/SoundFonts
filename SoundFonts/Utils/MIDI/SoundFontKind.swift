// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

enum SoundFontKindError: Error {
    case invalidKind
}

enum SoundFontKind: Codable, Hashable {

    case builtin(resource: URL)
    case installed(fileName: String)

    private enum InternalKey: Int {
        case builtin = 0
        case installed = 1
    }

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

    var fileURL: URL {
        switch self {
        case .builtin(let resource):
            return resource
        case .installed(let fileName):
            return FileManager.default.localDocumentsDirectory.appendingPathComponent(fileName)
        }
    }

    var path: String { return fileURL.path }

    var removable: Bool {
        switch self {
        case .builtin(resource: _): return false
        case .installed(fileName: _): return true
        }
    }
}

