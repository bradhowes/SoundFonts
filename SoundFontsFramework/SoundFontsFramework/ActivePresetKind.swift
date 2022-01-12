// Copyright © 2020 Brad Howes. All rights reserved.

import DictionaryCoder
import Foundation
import os

/// Container for a user-selected SoundFont preset or a user-created favorite.
public enum ActivePresetKind: Equatable, CustomStringConvertible {
  /// Normal soundfont preset description
  case preset(soundFontAndPreset: SoundFontAndPreset)
  /// Favorite soundfont preset
  case favorite(favorite: Favorite)
  /// Exceptional case when there is no active preset
  case none

  public var description: String {
    switch self {
    case let .preset(soundFontAndPreset): return "<ActivePresetKind: preset \(soundFontAndPreset)>"
    case let .favorite(favorite): return "<ActivePresetKind: favorite \(favorite)>"
    case .none: return "<ActivePresetKind: none>"
    }
  }
}

public extension ActivePresetKind {

  /// Get the associated SoundFontAndPreset value
  var soundFontAndPreset: SoundFontAndPreset? {
    switch self {
    case .preset(let soundFontAndPreset): return soundFontAndPreset
    case .favorite(let favorite): return favorite.soundFontAndPreset
    case .none: return nil
    }
  }

  /// Get the associated Favorite value
  var favorite: Favorite? {
    switch self {
    case .preset: return nil
    case .favorite(let favorite): return favorite
    case .none: return nil
    }
  }
}

// MARK: - Codable

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

  private enum Keys: String, CodingKey {
    case internalKey
    case value
  }

  public enum DecodingFailure: Error { case invalidInternalKey }

  /**
   Construct from an encoded state.

   - parameter decode: state to read from
   */
  public init(from decoder: Decoder) throws {
    do {

      // Current encoding version using keyed container
      //
      let values = try decoder.container(keyedBy: Keys.self)
      guard let internalKey = InternalKey(rawValue: try values.decode(Int.self, forKey: .internalKey)) else {
        throw DecodingFailure.invalidInternalKey
      }

      switch internalKey {
      case .preset: self = .preset(soundFontAndPreset: try values.decode(SoundFontAndPreset.self, forKey: .value))
      case .favorite: self = .favorite(favorite: try values.decode(Favorite.self, forKey: .value))
      case .none: self = .none
      }
    } catch {
      let err = error
      do {

        // Legacy encoding using using un-keyed container
        //
        var container = try decoder.unkeyedContainer()
        guard let internalKey = InternalKey(rawValue: try container.decode(Int.self)) else {
          throw DecodingFailure.invalidInternalKey
        }

        switch internalKey {
        case .preset: self = .preset(soundFontAndPreset: try container.decode(SoundFontAndPreset.self))
        case .favorite: self = .favorite(favorite: try container.decode(Favorite.self))
        case .none: self = .none
        }
      } catch {
        throw err
      }
    }
  }

  /**
   Save to an encoded state.

   - parameter encoder: container to write to
   */
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Keys.self)
    try container.encode(InternalKey.key(for: self).rawValue, forKey: .internalKey)
    switch self {
    case .preset(let soundFontPreset): try container.encode(soundFontPreset, forKey: .value)
    case .favorite(let favorite): try container.encode(favorite, forKey: .value)
    case .none: break
    }
  }
}

// MARK: - SettingSerializable

extension ActivePresetKind: SettingSerializable {

  // Legacy support
  public static func decodeFromData(_ data: Data) -> ActivePresetKind? {
    try? JSONDecoder().decode(ActivePresetKind.self, from: data)
  }

  /**
   Attempt to obtain an active preset from dictionary

   - parameter dict: container to extract from
   - returns: optional ActivePresetKind
   */
  public static func decodeFromDict(_ dict: [String: Any]) -> ActivePresetKind? {
    try? DictionaryCoder.DictionaryDecoder().decode(ActivePresetKind.self, from: dict)
  }

  /**
   Attempt to encode an ActivePresetKind value to a dictionary

   - returns: optional dictionary containing the encoded value
   */
  public func encodeToDict() -> [String: Any]? { try? DictionaryCoder.DictionaryEncoder().encode(self) }

  public static func register(key: String, value: ActivePresetKind, source: UserDefaults) {
    if let dict = value.encodeToDict() {
      source.register(defaults: [key: dict])
    }
  }

  public static func get(key: String, defaultValue: ActivePresetKind, source: Settings) -> ActivePresetKind {

    // Hand-decoding from Settings value to support legacy values which used Data containers.
    // Fetch the value as `Any` and then try to work with it as a Dict or as a Data container.
    //
    guard let raw = source.raw(key: key) else {
      source.set(key: key, value: defaultValue.encodeToDict())
      return defaultValue
    }
    if let container = raw as? [String: Any] {
      return ActivePresetKind.decodeFromDict(container) ?? defaultValue
    }
    else if let container = raw as? Data {
      return ActivePresetKind.decodeFromData(container) ?? defaultValue
    }
    return defaultValue
  }

  public static func set(key: String, value: ActivePresetKind, source: Settings) {
    if let dict = value.encodeToDict() {
      source.set(key: key, value: dict)
    }
  }
}
