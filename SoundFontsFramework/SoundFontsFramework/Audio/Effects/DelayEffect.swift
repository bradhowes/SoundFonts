// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation

/// Delay audio effect by way of Apple's AVAudioUnitDelay component.
final class DelayEffect: NSObject {

  let activeQueue = DispatchQueue(label: "ActiveDelayEffect", qos: .background, target: DispatchQueue.global(qos: .background))
  let audioUnit = AVAudioUnitDelay()

  private var _active: DelayConfig

  private let _factoryPresetDefs = [
    AUPresetEntry(
      name: "Slap Back",
      config: DelayConfig(
        enabled: true, time: 0.25, feedback: 0, cutoff: 20_000.0,
        wetDryMix: 50)),
    AUPresetEntry(
      name: "Muffled Echo",
      config: DelayConfig(
        enabled: true, time: 0.38, feedback: 60, cutoff: 980,
        wetDryMix: 35)),
    AUPresetEntry(
      name: "Fripptastic",
      config: DelayConfig(
        enabled: true, time: 2.0, feedback: 95, cutoff: 640,
        wetDryMix: 50))
  ]

  lazy var factoryPresetConfigs: [DelayConfig] = _factoryPresetDefs.map { $0.config }
  lazy var factoryPresets: [AUAudioUnitPreset] = _factoryPresetDefs.enumerated().map {
    AUAudioUnitPreset(number: $0.offset, name: $0.element.name)
  }

  var active: DelayConfig {
    get { activeQueue.sync { self._active } }
    set { activeQueue.async { [weak self] in
      guard let self = self else { return }
      self._active = newValue
      self.applyActiveConfig(newValue)
    } }
  }

  override init() {
    self._active = DelayConfig(
      enabled: true, time: 1.0, feedback: 50.0, cutoff: 15_000.0, wetDryMix: 35.0)
    super.init()
    applyActiveConfig(self.active)
  }
}

extension DelayEffect {

  private func applyActiveConfig(_ config: DelayConfig) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.audioUnit.bypass = !config.enabled
      self.audioUnit.wetDryMix = config.wetDryMix
      self.audioUnit.delayTime = Double(config.time)
      self.audioUnit.feedback = config.feedback
      self.audioUnit.lowPassCutoff = config.cutoff
    }
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .delayConfigChanged, object: nil)
    }
  }
}
