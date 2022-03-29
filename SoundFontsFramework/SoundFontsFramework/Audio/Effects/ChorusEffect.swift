// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation

/// Chorus audio effect
public final class ChorusEffect: NSObject {

  public var audioUnit: AVAudioUnitEffect?

  private static let _factoryPresetDefs = [
    AUPresetEntry(
      name: "Angels",
      config: ChorusConfig(
        enabled: true, rate: 0.25, delay: 0.1, depth: 0.7, wetDryMix: 50, odd90: true))
  ]

  private static let _factoryPresetConfigs: [ChorusConfig] = _factoryPresetDefs.map { $0.config }
  private static let _factoryPresets: [AUAudioUnitPreset] = _factoryPresetDefs.enumerated().map {
    AUAudioUnitPreset(number: $0.offset, name: $0.element.name)
  }

  public var factoryPresetConfigs: [ChorusConfig] { Self._factoryPresetConfigs }
  public var factoryPresets: [AUAudioUnitPreset] { Self._factoryPresets }

  public var active: ChorusConfig { didSet { applyActiveConfig(active) } }

  public override init() {

    let componentDescription = AudioComponentDescription(componentType: FourCharCode(""),
                                                         componentSubType: FourCharCode(""),
                                                         componentManufacturer: FourCharCode(""),
                                                         componentFlags: 0, componentFlagsMask: 0)

    AVAudioUnit.instantiate(with: componentDescription, options: []) { audioUnit, err in
      guard let audioUnit = audioUnit as? AVAudioUnitEffect else {
        fatalError("failed to allocate chorus audio unit - " + (err?.localizedDescription ?? "???"))
      }
      self.audioUnit = audioUnit
      self.active = Self._factoryPresetConfigs[0]
      self.applyActiveConfig(self.active)
    }

    super.init()
  }
}

extension ChorusEffect {

  private func applyActiveConfig(_ config: ChorusConfig) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.audioUnit.bypass = !config.enabled
      self.audioUnit.wetDryMix = config.wetDryMix
      self.audioUnit.rate = config.rate
      self.audioUnit.feedback = config.feedback
      self.audioUnit.lowPassCutoff = config.cutoff
    }
  }
}
