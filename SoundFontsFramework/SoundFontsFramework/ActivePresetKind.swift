// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os

/// Container for a user-selected soundfont patch or a user-created favorite.
public enum ActivePresetKind: Equatable {
  /// Normal soundfont patch description
  case preset(soundFontAndPatch: SoundFontAndPreset)
  /// Favorite soundfont patch
  case favorite(favorite: Favorite)
  /// Exceptional case when there is no active patch
  case none
}

extension ActivePresetKind {
  /// Get the associated SoundFontAndPatch value
  public var soundFontAndPatch: SoundFontAndPreset? {
    switch self {
    case .preset(let soundFontAndPatch): return soundFontAndPatch
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

    static func key(for kind: ActivePresetKind) -> InternalKey {
      switch kind {
      case .preset(soundFontAndPatch: _): return .preset
      case .favorite(favorite: _): return .favorite
      case .none: return .none
      }
    }
  }

  /**
     Attempt to obtain an active patch from data

     - parameter data: container to extract from
     - returns: optional ActivePatchKind
     */
  public static func decodeFromData(_ data: Data) -> ActivePresetKind? {
    try? JSONDecoder().decode(ActivePresetKind.self, from: data)
  }

  /**
     Attempt to encode an ActivePatchKind value to Data

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
    case .preset: self = .preset(soundFontAndPatch: try container.decode(SoundFontAndPreset.self))
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
    case .preset(let soundFontPatch): try container.encode(soundFontPatch)
    case .favorite(let favorite): try container.encode(favorite)
    case .none: break
    }
  }
}

extension ActivePresetKind: CustomStringConvertible {

  /// Get a description string for the value
  public var description: String {
    switch self {
    case let .preset(soundFontAndPatch: soundFontPatch): return ".preset(\(soundFontPatch)"
    case let .favorite(favorite: favorite): return ".favorite(\(favorite))"
    case .none: return "nil"
    }
  }
}
