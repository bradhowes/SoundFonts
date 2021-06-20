// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// Container for a user-selected soundfont preset or a user-created favorite.
public enum ActivePresetKind: Equatable {
  /// Normal soundfont preset description
  case preset(soundFontAndPreset: SoundFontAndPreset)
  /// Favorite soundfont preset
  case favorite(favorite: Favorite)
  /// Exceptional case when there is no active preset
  case none
}

extension ActivePresetKind {
  /// Get the associated SoundFontAndPreset value
  public var soundFontAndPreset: SoundFontAndPreset? {
    switch self {
    case .preset(let soundFontAndPreset): return soundFontAndPreset
    case .favorite(let favorite): return favorite.soundFontAndPreset
    case .none: return nil
    }
  }

  /// Get the associated Favorite value
  public var favorite: Favorite? {
    switch self {
    case .preset: return nil
    case .favorite(let favorite): return favorite
    case .none: return nil
    }
  }
}

extension ActivePresetKind: Codable {

  private enum InternalKey: Int {
    case preset = 0
    case favorite = 1
    case none = 2

    fileprivate static func key(for kind: ActivePresetKind) -> InternalKey {
      switch kind {
      case .preset(soundFontAndPreset: _): return .preset
      case .favorite(favorite: _): return .favorite
      case .none: return .none
      }
    }
  }

  /**
   Attempt to obtain an active preset from data

   - parameter data: container to extract from
   - returns: optional ActivePresetKind
   */
  public static func decodeFromData(_ data: Data) -> ActivePresetKind? {
    try? JSONDecoder().decode(ActivePresetKind.self, from: data)
  }

  /**
   Attempt to encode an ActivePresetKind value to Data

   - returns: optional Data containing the encoded value
   */
  public func encodeToData() -> Data? { try? JSONEncoder().encode(self) }

  /**
   Construct from an encoded state.

   - parameter decode: state to read from
   */
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    guard let kind = InternalKey(rawValue: try container.decode(Int.self)) else { fatalError() }
    switch kind {
    case .preset: self = .preset(soundFontAndPreset: try container.decode(SoundFontAndPreset.self))
    case .favorite: self = .favorite(favorite: try container.decode(Favorite.self))
    case .none: self = .none
    }
  }

  /**
   Save to an encoded state.

   - parameter encoder: container to write to
   */
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(InternalKey.key(for: self).rawValue)
    switch self {
    case .preset(let soundFontPreset): try container.encode(soundFontPreset)
    case .favorite(let favorite): try container.encode(favorite)
    case .none: break
    }
  }
}

extension ActivePresetKind: CustomStringConvertible {

  /// Get a description string for the value
  public var description: String {
    switch self {
    case let .preset(soundFontAndPreset: soundFontPreset): return ".preset(\(soundFontPreset)"
    case let .favorite(favorite: favorite): return ".favorite(\(favorite))"
    case .none: return "nil"
    }
  }
}
