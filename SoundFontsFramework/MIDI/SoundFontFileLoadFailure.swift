// Copyright (c) 2020 Brad Howes. All rights reserved.

public enum SoundFontFileLoadFailure: Error {
    case emptyFile(_ file: String)
    case invalidSoundFont(_ file: String)
    case unableToCreateFile(_ file: String)
}

extension SoundFontFileLoadFailure {

    var id: Int {
        switch self {
        case .emptyFile: return 1
        case .invalidSoundFont: return 2
        case .unableToCreateFile: return 3
        }
    }

    var file: String {
        switch self {
        case .emptyFile(let file): return file
        case .invalidSoundFont(let file): return file
        case .unableToCreateFile(let file): return file
        }
    }
}

extension SoundFontFileLoadFailure: Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension SoundFontFileLoadFailure: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
