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

    private var reverbEffect: Reverb!
    private var delayEffect: Delay!
    private var activePatchManager: ActivePatchManager!
    private var soundFonts: SoundFonts!
    private var favorites: Favorites!

    public override func viewDidLoad() {
        reverbRoom.dataSource = self
        reverbRoom.delegate = self
        reverbRoom.selectRow(Settings.instance.reverbPreset, inComponent: 0, animated: false)

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

        reverbWetDryMix.value = Settings.instance.reverbWetDryMix
        updateReverbState(Settings.instance.reverbEnabled)

        delayTime.value = Settings.instance.delayTime
        delayFeedback.value = Settings.instance.delayFeedback

        delayCutoff.value = log10(Settings.instance.delayCutoff)

        delayWetDryMix.value = Settings.instance.delayWetDryMix
        updateDelayState(Settings.instance.delayEnabled)
    }

    @IBAction func toggleReverbEnabled(_ sender: UIButton) {
        reverbEffect.active = reverbEffect.active.setEnabled(!reverbEffect.active.enabled)
        updateReverbState(reverbEffect.active.enabled)
        updatePreset()
    }

    @IBAction func toggleReverbGlobal(_ sender: UIButton) {
        let value = !Settings.instance.reverbGlobal
        Settings.instance.reverbGlobal = value
        reverbGlobal.showEnabled(value)
        updatePreset()
    }

    @IBAction func toggleDelayEnabled(_ sender: UIButton) {
        delayEffect.active = delayEffect.active.setEnabled(!delayEffect.active.enabled)
        updateDelayState(delayEffect.active.enabled)
        updatePreset()
    }

    @IBAction func toggleDelayGlobal(_ sender: UIButton) {
        let value = !Settings.instance.delayGlobal
        Settings.instance.delayGlobal = value
        delayGlobal.showEnabled(value)
        updatePreset()
    }

    @IBAction func changeReverbWebDryMix(_ sender: Any) {
        showReverbMixValue()
        reverbEffect.active = reverbEffect.active.setWetDryMix(reverbWetDryMix.value)
        updatePreset()
    }

    @IBAction func changeDelayTime(_ sender: Any) {
        showDelayTime()
        delayEffect.active = delayEffect.active.setTime(delayTime.value)
        updatePreset()
    }

    @IBAction func changeDelayFeedback(_ sender: Any) {
        showDelayFeedback()
        delayEffect.active = delayEffect.active.setFeedback(delayFeedback.value)
        updatePreset()
    }

    @IBAction func changeDelayCutoff(_ sender: Any) {
        showDelayCutoff()
        delayEffect.active = delayEffect.active.setCutoff(pow(10.0, delayCutoff.value))
        updatePreset()
    }

    @IBAction func changeDelayWetDryMix(_ sender: Any) {
        let value = delayWetDryMix.value
        delayWetDryMixLabel.showStatus(String(format: "%.0f", value) + "%")
        delayEffect.active = delayEffect.active.setWetDryMix(value)
        updatePreset()
    }
}

extension EffectsController: ControllerConfiguration {
    public func establishConnections(_ router: ComponentContainer) {
        soundFonts = router.soundFonts
        favorites = router.favorites
        activePatchManager = router.activePatchManager
        activePatchManager.subscribe(self, notifier: activePatchChange)
        reverbEffect = router.reverbEffect
        delayEffect = router.delayEffect
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
        os_log(.info, log: log, "new reverb room: %d", Reverb.roomPresets[row].rawValue)
        reverbEffect.active = reverbEffect.active.setPreset(row)
        updatePreset()
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

    private func updatePreset() {
        guard let presetConfig = activePatchManager.presetConfig else { return }

        let delayConfig = Settings.instance.delayGlobal ? presetConfig.delayConfig : (delayEffect.active.enabled ? delayEffect.active : nil)
        let reverbConfig = Settings.instance.reverbGlobal ?
            presetConfig.reverbConfig :
            (reverbEffect.active.enabled ? reverbEffect.active : nil)

        if let favorite = activePatchManager.favorite {
            favorites.setEffects(favorite: favorite, delay: delayConfig, reverb: reverbConfig)
        }
        else if let soundFontAndPatch = activePatchManager.soundFontAndPatch {
            soundFonts.setEffects(soundFontAndPatch: soundFontAndPatch, delay: delayConfig, reverb: reverbConfig)
        }
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        guard case .active = event else { return }
        guard let patch = activePatchManager.patch else { return }
        let presetConfig = activePatchManager.favorite?.presetConfig ?? patch.presetConfig

        if !Settings.instance.reverbGlobal {
            if let reverbConfig = presetConfig.reverbConfig {
                update(config: reverbConfig)
            }
            else {
                updateReverbState(false)
            }
        }

        if !Settings.instance.delayGlobal {
            if let delayConfig = presetConfig.delayConfig {
                update(config: delayConfig)
            }
            else {
                updateDelayState(false)
            }
        }
    }

    private func alpha(for enabled: Bool) -> CGFloat { enabled ? 1.0 : 0.5 }

    private func update(config: ReverbConfig) {
        reverbRoom.selectRow(config.preset, inComponent: 0, animated: true)
        reverbWetDryMix.setValue(config.wetDryMix, animated: true)
        showReverbMixValue()
        updateReverbState(config.enabled)
    }

    private func updateReverbState(_ enabled: Bool) {
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
        delayTime.setValue(config.time, animated: true)
        delayFeedback.setValue(config.feedback, animated: true)
        delayCutoff.setValue(log10(config.cutoff), animated: true)
        delayWetDryMix.setValue(config.wetDryMix, animated: true)
        updateDelayState(config.enabled)
    }

    private func updateDelayState(_ enabled: Bool) {
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

    private func showDelayTime() {
        delayTimeLabel.showStatus(String(format: "%.2f", delayTime.value) + "s")
    }

    private func showDelayFeedback() {
        delayFeedbackLabel.showStatus(String(format: "%.0f", delayFeedback.value) + "%")
    }

    private func showDelayCutoff() {
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
