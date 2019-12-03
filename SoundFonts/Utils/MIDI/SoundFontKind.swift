// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

enum SoundFontKind: Codable, Hashable {

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
        case .builtin(let resource): hasher.combine(resource.lastPathComponent)
        case .installed(let fileName): hasher.combine(fileName)
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

