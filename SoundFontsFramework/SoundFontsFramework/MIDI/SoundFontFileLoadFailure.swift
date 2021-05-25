// Copyright (c) 2020 Brad Howes. All rights reserved.

/// Types of SF2 load failures
public enum SoundFontFileLoadFailure: Error {
    /// File is empty
    case emptyFile(_ file: String)
    /// File contents is not in SF2 format
    case invalidFile(_ file: String)
    /// Could not make a copy of the file
    case unableToCreateFile(_ file: String)
}

extension SoundFontFileLoadFailure {

    var id: Int {
        switch self {
        case .emptyFile: return 1
        case .invalidFile: return 2
        case .unableToCreateFile: return 3
        }
    }

    var file: String {
        switch self {
        case .emptyFile(let file): return file
        case .invalidFile(let file): return file
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
