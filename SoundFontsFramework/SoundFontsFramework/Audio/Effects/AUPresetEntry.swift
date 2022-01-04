// Copyright © 2020 Brad Howes. All rights reserved.

/**
 Simple association between an AUv3 preset configuration and a name.
 */
public struct AUPresetEntry<Config>: Codable where Config: Codable {
  /// Name of the preset
  public let name: String
  /// Configuration of the preset
  public let config: Config
}
