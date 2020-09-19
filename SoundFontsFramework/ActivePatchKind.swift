// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/**
 Container for a user-selected soundfont patch or a user-created favorite.
 */
public enum ActivePatchKind: CustomStringConvertible, Codable, Equatable {

    /// Normal soundfont patch description
    case normal(soundFontAndPatch: SoundFontAndPatch)
    /// Favorite soundfont patch
    case favorite(favorite: LegacyFavorite)
    /// Exceptional case when there is no active patch
    case none

    private enum InternalKey: Int {
        case normal = 0
        case favorite = 1
        case none = 2

        static func key(for kind: ActivePatchKind) -> InternalKey {
            switch kind {
            case .normal(soundFontAndPatch: _): return .normal
            case .favorite(favorite:_): return .favorite
            case .none: return .none
            }
        }
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard let kind = InternalKey(rawValue: try container.decode(Int.self)) else { fatalError() }
        switch kind {
        case .normal: self = .normal(soundFontAndPatch: try container.decode(SoundFontAndPatch.self))
        case .favorite: self = .favorite(favorite: try container.decode(LegacyFavorite.self))
        case .none: self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(InternalKey.key(for: self).rawValue)
        switch self {
        case .normal(let soundFontPatch): try container.encode(soundFontPatch)
        case .favorite(let favorite): try container.encode(favorite)
        case .none: break
        }
    }
}

extension ActivePatchKind {

    /// Get the associated SoundFontAndPatch value
    public var soundFontAndPatch: SoundFontAndPatch? {
        switch self {
        case .normal(let soundFontAndPatch): return soundFontAndPatch
        case .favorite(let favorite): return favorite.soundFontAndPatch
        case .none: return nil
        }
    }

    /// Get the associated Favorite value
    public var favorite: LegacyFavorite? {
        switch self {
        case .normal: return nil
        case .favorite(let favorite): return favorite
        case .none: return nil
        }
    }

    /// Get a description string for the value
    public var description: String {
        switch self {
        case let .normal(soundFontAndPatch: soundFontPatch): return ".normal(\(soundFontPatch)"
        case let .favorite(favorite: favorite): return ".favorite(\(favorite))"
        case .none: return "nil"
        }
    }
}
