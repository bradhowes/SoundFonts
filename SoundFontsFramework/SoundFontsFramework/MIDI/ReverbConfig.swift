// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation

public struct ReverbConfig: Codable {

  public enum Key: String, CaseIterable {
    case enabled
    case preset
    case wetDryMix
  }

  public let enabled: Bool
  public let preset: Int
  public let wetDryMix: AUValue
}

extension ReverbConfig {
  public init() {
    self.init(
      enabled: Settings.instance.reverbEnabled,
      preset: Settings.instance.reverbPreset,
      wetDryMix: Settings.instance.delayWetDryMix)
  }

  public init?(state: [String: Any]) {
    guard let enabled = state[.enabled] == 0.0 ? false : true,
      let preset = state[.preset],
      let wetDryMix = state[.wetDryMix]
    else { return nil }
    self.init(enabled: enabled, preset: Int(preset), wetDryMix: wetDryMix)
  }

  public func setEnabled(_ enabled: Bool) -> ReverbConfig {
    ReverbConfig(enabled: enabled, preset: preset, wetDryMix: wetDryMix)
  }

  public func setPreset(_ preset: Int) -> ReverbConfig {
    ReverbConfig(enabled: enabled, preset: preset, wetDryMix: wetDryMix)
  }

  public func setWetDryMix(_ wetDryMix: Float) -> ReverbConfig {
    ReverbConfig(enabled: enabled, preset: preset, wetDryMix: wetDryMix)
  }

  public subscript(_ key: Key) -> AUValue {
    switch key {
    case .enabled: return AUValue(enabled ? 1.0 : 0.0)
    case .preset: return AUValue(preset)
    case .wetDryMix: return wetDryMix
    }
  }

  public var fullState: [String: Any] {
    [String: Any](
      uniqueKeysWithValues: zip(Key.allCases.map { $0.rawValue }, Key.allCases.map { self[$0] }))
  }
}

extension ReverbConfig: CustomStringConvertible {
  public var description: String {
    "<Reverb \(enabled) \(ReverbEffect.roomNames[preset]) \(wetDryMix)>"
  }
}

extension Dictionary where Key == String, Value == Any {
  fileprivate subscript(_ key: ReverbConfig.Key) -> AUValue? { self[key.rawValue] as? AUValue }
}
