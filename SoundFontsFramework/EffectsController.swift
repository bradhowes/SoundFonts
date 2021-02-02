// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVFoundation
import os

/**
 Manager of the strip informational strip between the keyboard and the SoundFont patches / favorites screens. Supports
 left/right swipes to switch the upper view, and two-finger left/right pan to adjust the keyboard range.
 */
public final class EffectsController: UIViewController {
    private let log = Logging.logger("Effects")

    @IBOutlet weak var reverbEnabled: UIButton!
    @IBOutlet weak var reverbGlobal: UIButton!
    @IBOutlet weak var reverbControls: UIStackView!
    @IBOutlet weak var reverbWetDryMix: Knob!
    @IBOutlet weak var reverbWetDryMixLabel: UILabel!
    @IBOutlet weak var reverbRoom: UIPickerView!

    @IBOutlet weak var delayEnabled: UIButton!
    @IBOutlet weak var delayGlobal: UIButton!
    @IBOutlet weak var delayControls: UIStackView!
    @IBOutlet weak var delayTime: Knob!
    @IBOutlet weak var delayTimeLabel: UILabel!
    @IBOutlet weak var delayFeedback: Knob!
    @IBOutlet weak var delayFeedbackLabel: UILabel!
    @IBOutlet weak var delayCutoff: Knob!
    @IBOutlet weak var delayCutoffLabel: UILabel!
    @IBOutlet weak var delayWetDryMix: Knob!
    @IBOutlet weak var delayWetDryMixLabel: UILabel!

    private var isMainApp: Bool = false
    private var activePatchManager: ActivePatchManager!
    private var soundFonts: SoundFonts!
    private var favorites: Favorites!

    private var reverbEffect: Reverb?
    private var delayEffect: Delay?

    public override func viewDidLoad() {

        reverbWetDryMix.minimumValue = 0
        reverbWetDryMix.maximumValue = 100
        reverbWetDryMix.value = 20

        delayTime.minimumValue = 0
        delayTime.maximumValue = 2
        delayTime.value = 1

        delayFeedback.minimumValue = -100.0
        delayFeedback.maximumValue =  100.0
        delayFeedback.value = 50.0

        delayCutoff.minimumValue = log10(10.0)
        delayCutoff.maximumValue = log10(20_000.0)
        delayCutoff.value =        log10(15_000.0)

        delayWetDryMix.minimumValue = 0
        delayWetDryMix.maximumValue = 100
        delayWetDryMix.value = 20

    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isMainApp else { return }
        reverbRoom.dataSource = self
        reverbRoom.delegate = self
        reverbRoom.reloadComponent(0)
        updateState()
    }

    @IBAction func toggleReverbEnabled(_ sender: UIButton) {
        guard let reverbEffect = self.reverbEffect else { return }
        reverbEffect.active = reverbEffect.active.setEnabled(!reverbEffect.active.enabled)
        updateReverbState(reverbEffect.active.enabled)
        updatePresetConfig()
    }

    @IBAction func toggleReverbGlobal(_ sender: UIButton) {
        let value = !Settings.instance.reverbGlobal
        Settings.instance.reverbGlobal = value
        reverbGlobal.showEnabled(value)
        updatePresetConfig()
    }

    @IBAction func toggleDelayEnabled(_ sender: UIButton) {
        guard let delayEffect = self.delayEffect else { return }
        delayEffect.active = delayEffect.active.setEnabled(!delayEffect.active.enabled)
        updateDelayState(delayEffect.active.enabled)
        updatePresetConfig()
    }

    @IBAction func toggleDelayGlobal(_ sender: UIButton) {
        let value = !Settings.instance.delayGlobal
        Settings.instance.delayGlobal = value
        delayGlobal.showEnabled(value)
        updatePresetConfig()
    }

    @IBAction func changeReverbWebDryMix(_ sender: Any) {
        guard let reverbEffect = self.reverbEffect else { return }
        showReverbMixValue()
        reverbEffect.active = reverbEffect.active.setWetDryMix(reverbWetDryMix.value)
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

extension EffectsController: ControllerConfiguration {
    public func establishConnections(_ router: ComponentContainer) {
        guard router.isMainApp else { return }
        isMainApp = true
        soundFonts = router.soundFonts
        favorites = router.favorites
        activePatchManager = router.activePatchManager
        router.subscribe(self, notifier: routerChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
    }
}

extension EffectsController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        Reverb.roomNames.count
    }
}

extension EffectsController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let reverbEffect = self.reverbEffect else { return }
        os_log(.info, log: log, "new reverb room: %d", Reverb.roomPresets[row].rawValue)
        reverbEffect.active = reverbEffect.active.setPreset(row)
        updatePresetConfig()
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int,
                           reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.init(name: "Eurostile", size: 17.0)
            pickerLabel?.textAlignment = .center
        }

        pickerLabel?.attributedText =
            NSAttributedString(string: Reverb.roomNames[row],
                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemTeal])

        return pickerLabel!
    }
}

extension EffectsController {

    private func updateGlobalConfig() {
        if let reverbEffect = self.reverbEffect, Settings.instance.reverbGlobal {
            os_log(.info, log: log, "updating global reverb settings")
            let config = reverbEffect.active
            Settings.instance.reverbEnabled = config.enabled
            Settings.instance.reverbPreset = config.preset
            Settings.instance.reverbWetDryMix = config.wetDryMix
        }

        if let delayEffect = self.delayEffect, Settings.instance.delayGlobal {
            os_log(.info, log: log, "updating global delay settings")
            let config = delayEffect.active
            Settings.instance.delayEnabled = config.enabled
            Settings.instance.delayTime = config.time
            Settings.instance.delayFeedback = config.feedback
            Settings.instance.delayCutoff = config.cutoff
            Settings.instance.delayWetDryMix = config.wetDryMix
        }
    }

    private func updatePresetConfig() {
        guard let reverbEffect = self.reverbEffect,
              let delayEffect = self.delayEffect
        else {
            return
        }

        os_log(.info, log: log, "updatePresetConfig")

        let reverbConfig: ReverbConfig? = {
            if Settings.instance.reverbGlobal {
                os_log(.info, log: log, "updating global reverb")
                return activePatchManager.presetConfig?.reverbConfig
            } else if reverbEffect.active.enabled {
                os_log(.info, log: log, "updating preset reverb")
                return reverbEffect.active
            } else {
                os_log(.info, log: log, "nil reverb preset")
                return nil
            }
        }()

        let delayConfig: DelayConfig? = {
            if Settings.instance.delayGlobal {
                os_log(.info, log: log, "updating global delay")
                return activePatchManager.presetConfig?.delayConfig
            } else if delayEffect.active.enabled {
                os_log(.info, log: log, "updating preset delay")
                return delayEffect.active
            } else {
                os_log(.info, log: log, "nil delay preset")
                return nil
            }
        }()

        if let favorite = activePatchManager.favorite {
            os_log(.info, log: log, "updating favorite - delay: %{public}s reverb: %{public}s",
                   delayConfig?.description ?? "nil", reverbConfig?.description ?? "nil")
            favorites.setEffects(favorite: favorite, delay: delayConfig, reverb: reverbConfig)
        }
        else if let soundFontAndPatch = activePatchManager.soundFontAndPatch {
            os_log(.info, log: log, "updating preset - delay: %{public}s reverb: %{public}s",
                   delayConfig?.description ?? "nil", reverbConfig?.description ?? "nil")
            soundFonts.setEffects(soundFontAndPatch: soundFontAndPatch, delay: delayConfig, reverb: reverbConfig)
        }

        updateGlobalConfig()
    }

    private func routerChange(_ event: ComponentContainerEvent) {
        switch event {
        case .reverbAvailable(let reverb):
            reverbEffect = reverb
            updateState()

        case .delayAvailable(let delay):
            delayEffect = delay
            updateState()

        case .samplerAvailable: break
        }
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        guard case .active = event else { return }
        updateState()
    }

    private func updateState() {
        os_log(.info, log: log, "updateState")
        let presetConfig = activePatchManager.favorite?.presetConfig ?? activePatchManager.patch?.presetConfig

        reverbGlobal.showEnabled(Settings.instance.reverbGlobal)
        if Settings.instance.reverbGlobal {
            os_log(.info, log: log, "showing global reverb state")
            let config = ReverbConfig()
            update(config: config)
        }
        else {
            guard let reverbEffect = self.reverbEffect else { return }
            let config = presetConfig?.reverbConfig ?? reverbEffect.active.setEnabled(false)
            os_log(.info, log: log, "showing preset reverb state - %{public}s", config.description)
            update(config: config)
        }

        delayGlobal.showEnabled(Settings.instance.delayGlobal)
        if Settings.instance.delayGlobal {
            os_log(.info, log: log, "showing global delay state")
            update(config: DelayConfig())
        }
        else {
            guard let delayEffect = self.delayEffect else { return }
            let config = presetConfig?.delayConfig ?? delayEffect.active.setEnabled(false)
            os_log(.info, log: log, "showing preset delay state - %{public}s", config.description)
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
        }
        else {
            delayCutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
        }
    }

    private func showDelayMixValue() {
        delayWetDryMixLabel.showStatus(String(format: "%.0f", delayWetDryMix.value) + "%")
    }
}
