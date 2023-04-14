// Copyright © 2018 Brad Howes. All rights reserved.

import AVFoundation
import UIKit
import os

/// View controller for the effects controls view. Much of this functionality is duplicated in the AUv3 effects
/// components. Should be refactored and shared between the two.
final class EffectsController: UIViewController {
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

  private var isMainApp: Bool = false
  private var activePresetManager: ActivePresetManager!
  private var soundFonts: SoundFontsProvider!
  private var favorites: FavoritesProvider!
  private var settings: Settings!

  private var audioEngine: AudioEngine?
  private var reverbEffect: ReverbEffect? { audioEngine?.reverbEffect }
  private var delayEffect: DelayEffect? { audioEngine?.delayEffect }

  private var reverbConfigObserver: NSObjectProtocol?
  private var delayConfigObserver: NSObjectProtocol?

  public override func viewDidLoad() {

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

// MARK: - ControllerConfiguration

extension EffectsController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    guard router.isMainApp else { return }
    settings = router.settings
    isMainApp = router.isMainApp
    soundFonts = router.soundFonts
    favorites = router.favorites
    activePresetManager = router.activePresetManager

    router.subscribe(self, notifier: routerChangeNotificationInBackground)
    activePresetManager.subscribe(self, notifier: activePresetChangedNotificationInBackground)

    if let audioEngine = router.audioEngine {
      self.audioEngine = audioEngine
      updateState()
      registerConfigObservers()
    }
  }
}

extension EffectsController: UIPickerViewDataSource {
  public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
  public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    ReverbEffect.roomNames.count
  }
}

// MARK: - Reverb Room Picker

extension EffectsController: UIPickerViewDelegate {

  public func pickerView(
    _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int
  ) {
    guard let reverbEffect = self.reverbEffect else { return }
    os_log(.debug, log: log, "new reverb room: %d", ReverbEffect.roomPresets[row].rawValue)
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

private extension EffectsController {

  func updateGlobalConfig() {
    if let reverbEffect = self.reverbEffect, settings.reverbGlobal {
      os_log(.debug, log: log, "updating global reverb settings")
      let config = reverbEffect.active
      settings.reverbEnabled = config.enabled
      settings.reverbPreset = config.preset
      settings.reverbWetDryMix = config.wetDryMix
    }

    if let delayEffect = self.delayEffect, settings.delayGlobal {
      os_log(.debug, log: log, "updating global delay settings")
      let config = delayEffect.active
      settings.delayEnabled = config.enabled
      settings.delayTime = config.time
      settings.delayFeedback = config.feedback
      settings.delayCutoff = config.cutoff
      settings.delayWetDryMix = config.wetDryMix
    }
  }

  func updatePresetConfig() {
    guard let reverbEffect = self.reverbEffect,
          let delayEffect = self.delayEffect
    else {
      return
    }

    os_log(.debug, log: log, "updatePresetConfig")

    let reverbConfig: ReverbConfig? = {
      if settings.reverbGlobal {
        os_log(.debug, log: log, "updating global reverb")
        return activePresetManager.activePresetConfig?.reverbConfig
      } else if reverbEffect.active.enabled {
        os_log(.debug, log: log, "updating preset reverb")
        return reverbEffect.active
      } else {
        os_log(.debug, log: log, "nil reverb preset")
        return nil
      }
    }()

    let delayConfig: DelayConfig? = {
      if settings.delayGlobal {
        os_log(.debug, log: log, "updating global delay")
        return activePresetManager.activePresetConfig?.delayConfig
      } else if delayEffect.active.enabled {
        os_log(.debug, log: log, "updating preset delay")
        return delayEffect.active
      } else {
        os_log(.debug, log: log, "nil delay preset")
        return nil
      }
    }()

    if let favorite = activePresetManager.activeFavorite {
      os_log(.debug, log: log, "updating favorite - delay: %{public}s reverb: %{public}s",
             delayConfig?.description ?? "nil", reverbConfig?.description ?? "nil")
      favorites.setEffects(favorite: favorite, delay: delayConfig, reverb: reverbConfig)
    } else if let soundFontAndPreset = activePresetManager.active.soundFontAndPreset {
      os_log(.debug, log: log, "updating preset - delay: %{public}s reverb: %{public}s",
             delayConfig?.description ?? "nil", reverbConfig?.description ?? "nil")
      soundFonts.setEffects(soundFontAndPreset: soundFontAndPreset, delay: delayConfig, reverb: reverbConfig)
    }

    updateGlobalConfig()
  }

  func routerChangeNotificationInBackground(_ event: ComponentContainerEvent) {
    switch event {
    case .audioEngineAvailable(let audioEngine):
      DispatchQueue.main.async {
        self.audioEngine = audioEngine
        self.updateState()
        self.registerConfigObservers()
      }
    }
  }

  func activePresetChangedNotificationInBackground(_ event: ActivePresetEvent) {
    guard case .changed = event else { return }
    DispatchQueue.main.async { self.updateState() }
  }

  func updateState() {
    os_log(.debug, log: log, "updateState")
    let presetConfig = activePresetManager.activePresetConfig

    reverbGlobal.showEnabled(settings.reverbGlobal)
    if settings.reverbGlobal {
      os_log(.debug, log: log, "showing global reverb state")
      let config = ReverbConfig(settings: settings)
      update(config: config)
    } else {
      guard let reverbEffect = self.reverbEffect else { return }
      let config = presetConfig?.reverbConfig ?? reverbEffect.active.setEnabled(false)
      os_log(.debug, log: log, "showing preset reverb state - %{public}s", config.description)
      update(config: config)
    }

    delayGlobal.showEnabled(settings.delayGlobal)
    if settings.delayGlobal {
      os_log(.debug, log: log, "showing global delay state")
      update(config: DelayConfig(settings: settings))
    } else {
      guard let delayEffect = self.delayEffect else { return }
      let config = presetConfig?.delayConfig ?? delayEffect.active.setEnabled(false)
      os_log(.debug, log: log, "showing preset delay state - %{public}s", config.description)
      update(config: config)
    }
  }

  func alpha(for enabled: Bool) -> CGFloat { enabled ? 1.0 : 0.5 }

  func update(config: ReverbConfig) {
    os_log(.debug, log: log, "update ReverbConfig - %{public}s", config.description)
    reverbRoom.selectRow(config.preset, inComponent: 0, animated: true)
    reverbWetDryMix.setValue(config.wetDryMix, animated: true)
    showReverbMixValue()
    updateReverbState(config.enabled)
  }

  func updateReverbState(_ enabled: Bool) {
    os_log(.debug, log: log, "updateReverbState - %d", enabled)
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

  func update(config: DelayConfig) {
    os_log(.debug, log: log, "update DelayConfig - %{public}s", config.description)
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

  func updateDelayState(_ enabled: Bool) {
    os_log(.debug, log: log, "updateDelayState - %d", enabled)
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

  func showReverbMixValue() {
    reverbWetDryMixLabel.showStatus(String(format: "%.0f", reverbWetDryMix.value) + "%")
  }

  func showDelayTimeValue() {
    delayTimeLabel.showStatus(String(format: "%.2f", delayTime.value) + "s")
  }

  func showDelayFeedbackValue() {
    delayFeedbackLabel.showStatus(String(format: "%.0f", delayFeedback.value) + "%")
  }

  func showDelayCutoffValue() {
    let value = pow(10.0, delayCutoff.value)
    if value < 1000.0 {
      delayCutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
    } else {
      delayCutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
    }
  }

  func showDelayMixValue() {
    delayWetDryMixLabel.showStatus(String(format: "%.0f", delayWetDryMix.value) + "%")
  }

  func registerConfigObservers() {
    if let reverbEffect = reverbEffect {
      reverbConfigObserver = NotificationCenter.default.addObserver(forName: .reverbConfigChanged,
                                                                    object: nil,
                                                                    queue: nil) { [weak self] _ in
        self?.update(config: reverbEffect.active)
      }
    }

    if let delayEffect = delayEffect {
      delayConfigObserver = NotificationCenter.default.addObserver(forName: .delayConfigChanged,
                                                                   object: nil,
                                                                   queue: nil) { [weak self] _ in
        self?.update(config: delayEffect.active)
      }
    }
  }
}
