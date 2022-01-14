// Copyright © 2018 Brad Howes. All rights reserved.

import AVFoundation
import UIKit
import os

/// View controller for the effects controls view. Much of this functionality is duplicated in the AUv3 effects
/// components. Should be refactored and shared between the two.
public final class EffectsController: UIViewController, Tasking {
  private lazy var log = Logging.logger("EffectsController")

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet private weak var reverbEnabled: UIButton!
  @IBOutlet private weak var reverbGlobal: UIButton!
  @IBOutlet private weak var reverbWetDryMix: Knob!
  @IBOutlet private weak var reverbWetDryMixLabel: UILabel!
  @IBOutlet private weak var reverbRoom: UIPickerView!

  @IBOutlet private weak var delayEnabled: UIButton!
  @IBOutlet private weak var delayGlobal: UIButton!
  @IBOutlet private weak var delayTime: Knob!
  @IBOutlet private weak var delayTimeLabel: UILabel!
  @IBOutlet private weak var delayFeedback: Knob!
  @IBOutlet private weak var delayFeedbackLabel: UILabel!
  @IBOutlet private weak var delayCutoff: Knob!
  @IBOutlet private weak var delayCutoffLabel: UILabel!
  @IBOutlet private weak var delayWetDryMix: Knob!
  @IBOutlet private weak var delayWetDryMixLabel: UILabel!

  @IBOutlet private weak var chorusControls: UIStackView!
  @IBOutlet private weak var chorusEnabled: UIButton!
  @IBOutlet private weak var chorusGlobal: UIButton!
  @IBOutlet private weak var chorusRate: Knob!
  @IBOutlet private weak var chorusRateLabel: UILabel!
  @IBOutlet private weak var chorusDelay: Knob!
  @IBOutlet private weak var chorusDelayLabel: UILabel!
  @IBOutlet private weak var chorusDepth: Knob!
  @IBOutlet private weak var chorusDepthLabel: UILabel!
  @IBOutlet private weak var chorusFeedback: Knob!
  @IBOutlet private weak var chorusFeedbackLabel: UILabel!
  @IBOutlet private weak var chorusWetDryMix: Knob!
  @IBOutlet private weak var chorusWetDryMixLabel: UILabel!
  @IBOutlet private weak var chorusNegFeedback: UIButton!
  @IBOutlet private weak var chorusOdd90: UIButton!

  private var isMainApp: Bool = false
  private var activePresetManager: ActivePresetManager!
  private var soundFonts: SoundFonts!
  private var favorites: Favorites!
  private var settings: Settings!

  private var sampler: Sampler?
  private var reverbEffect: ReverbEffect? { sampler?.reverbEffect }
  private var delayEffect: DelayEffect? { sampler?.delayEffect }
  private var chorusEffect: ChorusEffect? { sampler?.chorusEffect}

  public override func viewDidLoad() {

    #if !DEBUG
    chorusControls.isHidden = true
    #endif

    view.isHidden = true

    reverbWetDryMix.minimumValue = 0
    reverbWetDryMix.maximumValue = 100
    reverbWetDryMix.value = 20

    delayTime.minimumValue = 0
    delayTime.maximumValue = 2
    delayTime.value = 1

    delayFeedback.minimumValue = -100.0
    delayFeedback.maximumValue = 100.0
    delayFeedback.value = 50.0

    delayCutoff.minimumValue = log10(10.0)
    delayCutoff.maximumValue = log10(20_000.0)
    delayCutoff.value = log10(15_000.0)

    delayWetDryMix.minimumValue = 0
    delayWetDryMix.maximumValue = 100
    delayWetDryMix.value = 20
  }
}

extension EffectsController {

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let contentSize = scrollView.contentSize
    let scrollViewSize = scrollView.frame.size
    var contentOffset = scrollView.contentOffset

    if contentSize.width < scrollViewSize.width {
      contentOffset.x = -(scrollViewSize.width - contentSize.width) / 2.0
    }

    if contentSize.height < scrollViewSize.height {
      contentOffset.y = -(scrollViewSize.height - contentSize.height) / 2.0
    }

    scrollView.setContentOffset(contentOffset, animated: false)
  }
}

extension EffectsController {

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard isMainApp else { return }
    view.isHidden = false
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard isMainApp else { return }
    reverbRoom.dataSource = self
    reverbRoom.delegate = self
    reverbRoom.reloadComponent(0)
    updateState()
  }
}

// MARK: - Reverb Actions

extension EffectsController {

  @IBAction func toggleReverbEnabled(_ sender: UIButton) {
    guard let reverbEffect = self.reverbEffect else { return }
    reverbEffect.active = reverbEffect.active.setEnabled(!reverbEffect.active.enabled)
    updateReverbState(reverbEffect.active.enabled)
    updatePresetConfig()
  }

  @IBAction func toggleReverbGlobal(_ sender: UIButton) {
    let value = !settings.reverbGlobal
    settings.reverbGlobal = value
    reverbGlobal.showEnabled(value)
    updatePresetConfig()
  }

  @IBAction func changeReverbWebDryMix(_ sender: Any) {
    guard let reverbEffect = self.reverbEffect else { return }
    showReverbMixValue()
    reverbEffect.active = reverbEffect.active.setWetDryMix(reverbWetDryMix.value)
    updatePresetConfig()
  }

}

// MARK: - Delay Actions

extension EffectsController {

  @IBAction func toggleDelayEnabled(_ sender: UIButton) {
    guard let delayEffect = self.delayEffect else { return }
    delayEffect.active = delayEffect.active.setEnabled(!delayEffect.active.enabled)
    updateDelayState(delayEffect.active.enabled)
    updatePresetConfig()
  }

  @IBAction func toggleDelayGlobal(_ sender: UIButton) {
    let value = !settings.delayGlobal
    settings.delayGlobal = value
    delayGlobal.showEnabled(value)
    updatePresetConfig()
  }

  @IBAction func changeDelayTime(_ sender: Any) {
    guard let delayEffect = self.delayEffect else { return }
    showDelayTimeValue()
    delayEffect.active = delayEffect.active.setTime(delayTime.value)
    updatePresetConfig()
  }

  @IBAction func changeDelayFeedback(_ sender: Any) {
    guard let delayEffect = self.delayEffect else { return }
    showDelayFeedbackValue()
    delayEffect.active = delayEffect.active.setFeedback(delayFeedback.value)
    updatePresetConfig()
  }

  @IBAction func changeDelayCutoff(_ sender: Any) {
    guard let delayEffect = self.delayEffect else { return }
    showDelayCutoffValue()
    delayEffect.active = delayEffect.active.setCutoff(pow(10.0, delayCutoff.value))
    updatePresetConfig()
  }

  @IBAction func changeDelayWetDryMix(_ sender: Any) {
    guard let delayEffect = self.delayEffect else { return }
    showDelayMixValue()
    delayEffect.active = delayEffect.active.setWetDryMix(delayWetDryMix.value)
    updatePresetConfig()
  }

}

// MARK: - Chorus Actions

extension EffectsController {

  @IBAction func toggleChorusEnabled(_ sender: UIButton) {
    guard let chorusEffect = self.chorusEffect else { return }
    chorusEffect.active = chorusEffect.active.setEnabled(!chorusEffect.active.enabled)
    updateChorusState(chorusEffect.active.enabled)
    updatePresetConfig()
  }

  @IBAction func toggleChorusGlobal(_ sender: UIButton) {
    let value = !settings.chorusGlobal
    settings.chorusGlobal = value
    chorusGlobal.showEnabled(value)
    updatePresetConfig()
  }

  @IBAction func changeChorusRate(_ sender: Any) {
    guard let chorusEffect = self.chorusEffect else { return }
    showChorusRateValue()
    chorusEffect.active = chorusEffect.active.setRate(chorusRate.value)
    updatePresetConfig()
  }

  @IBAction func changeChorusDelay(_ sender: Any) {
    guard let chorusEffect = self.chorusEffect else { return }
    showChorusDelayValue()
    chorusEffect.active = chorusEffect.active.setDelay(chorusDelay.value)
    updatePresetConfig()
  }

  @IBAction func changeChorusDepth(_ sender: Any) {
    guard let chorusEffect = self.chorusEffect else { return }
    showChorusDepthValue()
    chorusEffect.active = chorusEffect.active.setDepth(chorusDepth.value)
    updatePresetConfig()
  }

  @IBAction func changeChorusFeedback(_ sender: Any) {
    guard let chorusEffect = self.chorusEffect else { return }
    showChorusFeedbackValue()
    chorusEffect.active = chorusEffect.active.setFeedback(chorusFeedback.value)
    updatePresetConfig()
  }

  @IBAction func changeChorusWetDryMix(_ sender: Any) {
    guard let chorusEffect = self.chorusEffect else { return }
    showChorusMixValue()
    chorusEffect.active = chorusEffect.active.setWetDryMix(chorusWetDryMix.value)
    updatePresetConfig()
  }

  @IBAction func toggleChorusNegFeedback(_ sender: UIButton) {
    guard let chorusEffect = self.chorusEffect else { return }
    chorusEffect.active = chorusEffect.active.setNegFeedback(!chorusEffect.active.negFeedback)
    updatePresetConfig()
  }

  @IBAction func toggleChorusOdd90(_ sender: UIButton) {
    guard let chorusEffect = self.chorusEffect else { return }
    chorusEffect.active = chorusEffect.active.setOdd90(!chorusEffect.active.odd90)
    updatePresetConfig()
  }
}

// MARK: - ControllerConfiguration

extension EffectsController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    guard router.isMainApp else { return }
    settings = router.settings
    isMainApp = router.isMainApp
    soundFonts = router.soundFonts
    favorites = router.favorites
    activePresetManager = router.activePresetManager

    router.subscribe(self, notifier: routerChange_BT)
    activePresetManager.subscribe(self, notifier: activePresetChanged_BT)

    if let sampler = router.sampler {
      self.sampler = sampler
      updateState()
    }
  }
}

extension EffectsController: UIPickerViewDataSource {
  public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
  {
    ReverbEffect.roomNames.count
  }
}

// MARK: - Reverb Room Picker

extension EffectsController: UIPickerViewDelegate {

  public func pickerView(
    _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int
  ) {
    guard let reverbEffect = self.reverbEffect else { return }
    os_log(.info, log: log, "new reverb room: %d", ReverbEffect.roomPresets[row].rawValue)
    reverbEffect.active = reverbEffect.active.setPreset(row)
    updatePresetConfig()
  }

  public func pickerView(
    _ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int,
    reusing view: UIView?
  ) -> UIView {
    var pickerLabel: UILabel? = (view as? UILabel)
    if pickerLabel == nil {
      pickerLabel = UILabel()
      pickerLabel?.font = UIFont(name: "Eurostile", size: 17.0)
      pickerLabel?.textAlignment = .center
    }

    pickerLabel?.attributedText =
      NSAttributedString(
        string: ReverbEffect.roomNames[row],
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemTeal])

    return pickerLabel!
  }
}

extension EffectsController {

  private func updateGlobalConfig() {
    if let reverbEffect = self.reverbEffect, settings.reverbGlobal {
      os_log(.info, log: log, "updating global reverb settings")
      let config = reverbEffect.active
      settings.reverbEnabled = config.enabled
      settings.reverbPreset = config.preset
      settings.reverbWetDryMix = config.wetDryMix
    }

    if let delayEffect = self.delayEffect, settings.delayGlobal {
      os_log(.info, log: log, "updating global delay settings")
      let config = delayEffect.active
      settings.delayEnabled = config.enabled
      settings.delayTime = config.time
      settings.delayFeedback = config.feedback
      settings.delayCutoff = config.cutoff
      settings.delayWetDryMix = config.wetDryMix
    }

    if let chorusEffect = self.chorusEffect, settings.chorusGlobal {
      os_log(.info, log: log, "updating global chorus settings")
      let config = chorusEffect.active
      settings.chorusEnabled = config.enabled
      settings.chorusRate = config.rate
      settings.chorusDelay = config.delay
      settings.chorusDepth = config.depth
      settings.chorusFeedback = config.feedback
      settings.chorusWetDryMix = config.wetDryMix
    }
  }

  private func updatePresetConfig() {
    guard let reverbEffect = self.reverbEffect,
          let delayEffect = self.delayEffect
          // let chorusEffect = self.chorusEffect
    else {
      return
    }

    os_log(.info, log: log, "updatePresetConfig")

    let reverbConfig: ReverbConfig? = {
      if settings.reverbGlobal {
        os_log(.info, log: log, "updating global reverb")
        return activePresetManager.activePresetConfig?.reverbConfig
      } else if reverbEffect.active.enabled {
        os_log(.info, log: log, "updating preset reverb")
        return reverbEffect.active
      } else {
        os_log(.info, log: log, "nil reverb preset")
        return nil
      }
    }()

    let delayConfig: DelayConfig? = {
      if settings.delayGlobal {
        os_log(.info, log: log, "updating global delay")
        return activePresetManager.activePresetConfig?.delayConfig
      } else if delayEffect.active.enabled {
        os_log(.info, log: log, "updating preset delay")
        return delayEffect.active
      } else {
        os_log(.info, log: log, "nil delay preset")
        return nil
      }
    }()

    let chorusConfig: ChorusConfig? = {
      return nil
//      if settings.chorusGlobal {
//        os_log(.info, log: log, "updating global chorus")
//        return activePresetManager.activePresetConfig?.chorusConfig
//      } else if chorusEffect.active.enabled {
//        os_log(.info, log: log, "updating preset chorus")
//        return chorusEffect.active
//      } else {
//        os_log(.info, log: log, "nil chorus preset")
//        return nil
//      }
    }()

    if let favorite = activePresetManager.activeFavorite {
      os_log(.info, log: log, "updating favorite - delay: %{public}s reverb: %{public}s",
             delayConfig?.description ?? "nil", reverbConfig?.description ?? "nil")
      favorites.setEffects(favorite: favorite, delay: delayConfig, reverb: reverbConfig, chorus: chorusConfig)
    } else if let soundFontAndPreset = activePresetManager.active.soundFontAndPreset {
      os_log(.info, log: log, "updating preset - delay: %{public}s reverb: %{public}s",
             delayConfig?.description ?? "nil", reverbConfig?.description ?? "nil")
      soundFonts.setEffects(soundFontAndPreset: soundFontAndPreset, delay: delayConfig, reverb: reverbConfig,
                            chorus: chorusConfig)
    }

    updateGlobalConfig()
  }

  private func routerChange_BT(_ event: ComponentContainerEvent) {
    switch event {
    case .samplerAvailable(let sampler):
      Self.onMain {
        self.sampler = sampler
        self.updateState()
      }
    }
  }

  private func activePresetChanged_BT(_ event: ActivePresetEvent) {
    guard case .change = event else { return }
    Self.onMain { self.updateState() }
  }

  private func updateState() {
    os_log(.info, log: log, "updateState")
    let presetConfig = activePresetManager.activePresetConfig

    reverbGlobal.showEnabled(settings.reverbGlobal)
    if settings.reverbGlobal {
      os_log(.info, log: log, "showing global reverb state")
      let config = ReverbConfig(settings: settings)
      update(config: config)
    } else {
      guard let reverbEffect = self.reverbEffect else { return }
      let config = presetConfig?.reverbConfig ?? reverbEffect.active.setEnabled(false)
      os_log(.info, log: log, "showing preset reverb state - %{public}s", config.description)
      update(config: config)
    }

    delayGlobal.showEnabled(settings.delayGlobal)
    if settings.delayGlobal {
      os_log(.info, log: log, "showing global delay state")
      update(config: DelayConfig(settings: settings))
    } else {
      guard let delayEffect = self.delayEffect else { return }
      let config = presetConfig?.delayConfig ?? delayEffect.active.setEnabled(false)
      os_log(.info, log: log, "showing preset delay state - %{public}s", config.description)
      update(config: config)
    }

    chorusGlobal.showEnabled(settings.chorusGlobal)
    if settings.chorusGlobal {
      os_log(.info, log: log, "showing global chorus state")
      update(config: ChorusConfig(settings: settings))
    } else {
      guard let chorusEffect = self.chorusEffect else { return }
      let config = presetConfig?.chorusConfig ?? chorusEffect.active.setEnabled(false)
      os_log(.info, log: log, "showing preset chorus state - %{public}s", config.description)
      update(config: config)
    }
  }

  private func alpha(for enabled: Bool) -> CGFloat { enabled ? 1.0 : 0.5 }

  private func update(config: ReverbConfig) {
    os_log(.info, log: log, "update ReverbConfig - %{public}s", config.description)
    reverbRoom.selectRow(config.preset, inComponent: 0, animated: true)
    reverbWetDryMix.setValue(config.wetDryMix, animated: true)
    showReverbMixValue()
    updateReverbState(config.enabled)
  }

  private func updateReverbState(_ enabled: Bool) {
    os_log(.info, log: log, "updateReverbState - %d", enabled)
    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear)
    self.reverbEnabled.accessibilityLabel = enabled ? "DisableReverbEffect" : "EnableReverbEffect"
    animator.addAnimations {
      self.reverbEnabled.showEnabled(enabled)
      self.reverbGlobal.isEnabled = true
      self.reverbGlobal.isUserInteractionEnabled = true
      self.reverbWetDryMix.isEnabled = enabled
      self.reverbRoom.isUserInteractionEnabled = enabled
      self.reverbRoom.alpha = self.alpha(for: enabled)
      self.reverbWetDryMix.alpha = self.alpha(for: enabled)
      self.reverbWetDryMixLabel.alpha = self.alpha(for: enabled)
    }
    animator.startAnimation()
  }

  private func update(config: DelayConfig) {
    os_log(.info, log: log, "update DelayConfig - %{public}s", config.description)
    delayTime.setValue(config.time, animated: true)
    showDelayTimeValue()
    delayFeedback.setValue(config.feedback, animated: true)
    showDelayFeedbackValue()
    delayCutoff.setValue(log10(config.cutoff), animated: true)
    showDelayCutoffValue()
    delayWetDryMix.setValue(config.wetDryMix, animated: true)
    showDelayMixValue()
    updateDelayState(config.enabled)
  }

  private func updateDelayState(_ enabled: Bool) {
    os_log(.info, log: log, "updateDelayState - %d", enabled)
    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear)
    self.delayEnabled.accessibilityLabel = enabled ? "DisableDelayEffect" : "EnableDelayEffect"
    animator.addAnimations {
      self.delayEnabled.showEnabled(enabled)
      self.delayGlobal.isEnabled = true
      self.delayGlobal.isUserInteractionEnabled = true
      self.delayWetDryMix.isEnabled = enabled
      self.delayTime.isEnabled = enabled
      self.delayFeedback.isEnabled = enabled
      self.delayCutoff.isEnabled = enabled
      self.delayWetDryMix.alpha = self.alpha(for: enabled)
      self.delayWetDryMixLabel.alpha = self.alpha(for: enabled)
      self.delayTime.alpha = self.alpha(for: enabled)
      self.delayTimeLabel.alpha = self.alpha(for: enabled)
      self.delayFeedback.alpha = self.alpha(for: enabled)
      self.delayFeedbackLabel.alpha = self.alpha(for: enabled)
      self.delayCutoff.alpha = self.alpha(for: enabled)
      self.delayCutoffLabel.alpha = self.alpha(for: enabled)
    }
    animator.startAnimation()
  }

  private func update(config: ChorusConfig) {
    os_log(.info, log: log, "update ChorusConfig - %{public}s", config.description)
    chorusRate.setValue(config.rate, animated: true)
    showChorusRateValue()
    chorusDelay.setValue(config.delay, animated: true)
    showChorusDelayValue()
    chorusDepth.setValue(config.depth, animated: true)
    showChorusDepthValue()
    chorusFeedback.setValue(config.feedback, animated: true)
    showChorusFeedbackValue()
    chorusWetDryMix.setValue(config.wetDryMix, animated: true)
    showChorusMixValue()
    chorusNegFeedback.showEnabled(config.negFeedback)
    chorusOdd90.showEnabled(config.odd90)
    updateChorusState(config.enabled)
  }

  private func updateChorusState(_ enabled: Bool) {
    os_log(.info, log: log, "updateChorusState - %d", enabled)
    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear)
    self.chorusEnabled.accessibilityLabel = enabled ? "DisableChorusEffect" : "EnableChorusEffect"
    animator.addAnimations {
      self.chorusEnabled.showEnabled(enabled)
      self.chorusGlobal.isEnabled = true
      self.chorusGlobal.isUserInteractionEnabled = true
      self.chorusWetDryMix.isEnabled = enabled
      self.chorusRate.isEnabled = enabled
      self.chorusDelay.isEnabled = enabled
      self.chorusDepth.isEnabled = enabled
      self.chorusNegFeedback.isEnabled = enabled
      self.chorusOdd90.isEnabled = enabled
      self.chorusFeedback.isEnabled = enabled
      self.chorusWetDryMix.alpha = self.alpha(for: enabled)
      self.chorusWetDryMixLabel.alpha = self.alpha(for: enabled)
      self.chorusRate.alpha = self.alpha(for: enabled)
      self.chorusRateLabel.alpha = self.alpha(for: enabled)
      self.chorusDelay.alpha = self.alpha(for: enabled)
      self.chorusDelayLabel.alpha = self.alpha(for: enabled)
      self.chorusDepth.alpha = self.alpha(for: enabled)
      self.chorusDepthLabel.alpha = self.alpha(for: enabled)
      self.chorusFeedback.alpha = self.alpha(for: enabled)
      self.chorusFeedbackLabel.alpha = self.alpha(for: enabled)
    }
    animator.startAnimation()
  }

  private func showReverbMixValue() {
    reverbWetDryMixLabel.showStatus(String(format: "%.0f", reverbWetDryMix.value) + "%")
  }

  private func showDelayTimeValue() {
    delayTimeLabel.showStatus(String(format: "%.2f", delayTime.value) + "s")
  }

  private func showDelayFeedbackValue() {
    delayFeedbackLabel.showStatus(String(format: "%.0f", delayFeedback.value) + "%")
  }

  private func showDelayCutoffValue() {
    let value = pow(10.0, delayCutoff.value)
    if value < 1000.0 {
      delayCutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
    } else {
      delayCutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
    }
  }

  private func showDelayMixValue() {
    delayWetDryMixLabel.showStatus(String(format: "%.0f", delayWetDryMix.value) + "%")
  }

  private func showChorusRateValue() {
    chorusRateLabel.showStatus(String(format: "%.0f", chorusRate.value) + "Hz")
  }

  private func showChorusDelayValue() {
    chorusDelayLabel.showStatus(String(format: "%.0f", chorusDelay.value) + "s")
  }

  private func showChorusDepthValue() {
    chorusDepthLabel.showStatus(String(format: "%.0f", chorusDepth.value) + "%")
  }

  private func showChorusFeedbackValue() {
    chorusFeedbackLabel.showStatus(String(format: "%.0f", chorusFeedback.value) + "%")
  }

  private func showChorusMixValue() {
    chorusWetDryMixLabel.showStatus(String(format: "%.0f", chorusWetDryMix.value) + "%")
  }
}
