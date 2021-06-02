// Copyright © 2020 Brad Howes. All rights reserved.

public struct PresetEntry<Config>: Codable where Config: Codable {
  public let name: String
  public let config: Config

  public init(name: String, config: Config) {
    self.name = name
    self.config = config
  }
}
