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
    @IBOutlet weak var reverbMixLabel: UILabel!
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
    @IBOutlet weak var delayMixLabel: UILabel!

    private var delay: Delay!
    private var reverb: Reverb!
    private var activePatchManager: ActivePatchManager!
    private var soundFonts: SoundFonts!

    public override func viewDidLoad() {
        reverbRoom.dataSource = self
        reverbRoom.delegate = self
        reverbRoom.selectRow(Settings.instance.reverbPreset, inComponent: 0, animated: false)
        reverbWetDryMix.value = Settings.instance.reverbWetDryMix
        updateReverbState(Settings.instance.reverbEnabled)

        delayTime.value = Settings.instance.delayTime
        delayFeedback.value = Settings.instance.delayFeedback
        delayCutoff.value = Settings.instance.delayCutoff
        delayWetDryMix.value = Settings.instance.delayWetDryMix
        updateDelayState(Settings.instance.delayEnabled)
    }

    @IBAction func toggleReverbEnabled(_ sender: UIButton) {
        let enabled = !reverb.active.enabled
        updateReverbState(enabled)
        reverb.active = reverb.active.setEnabled(enabled)
        updatePreset()
    }

    @IBAction func toggleReverbGlobal(_ sender: UIButton) {
        let value = !Settings.instance.reverbGlobal
        reverbGlobal.showEnabled(value)
        Settings.instance.reverbGlobal = value
        updatePreset()
    }

    @IBAction func toggleDelayEnabled(_ sender: UIButton) {
        let enabled = !delay.active.enabled
        updateDelayState(enabled)
        delay.active = delay.active.setEnabled(enabled)
        updatePreset()
    }

    @IBAction func toggleDelayGlobal(_ sender: UIButton) {
        let value = !Settings.instance.delayGlobal
        delayGlobal.showEnabled(value)
        Settings.instance.delayGlobal = value
        updatePreset()
    }

    @IBAction func changeReverbWebDryMix(_ sender: Any) {
        showReverbMixValue()
        reverb.active = reverb.active.setWetDryMix(reverbWetDryMix.value)
        updatePreset()
    }

    @IBAction func changeDelayTime(_ sender: Any) {
        showDelayTime()
        delay.active = delay.active.setTime(delayTime.value)
        updatePreset()
    }

    @IBAction func changeDelayFeedback(_ sender: Any) {
        showDelayFeedback()
        delay.active = delay.active.setFeedback(delayFeedback.value)
        updatePreset()
    }

    @IBAction func changeDelayCutoff(_ sender: Any) {
        showDelayCutoff()
        delay.active = delay.active.setCutoff(delayCutoff.value)
        updatePreset()
    }

    @IBAction func changeDelayWetDryMix(_ sender: Any) {
        let value = delayWetDryMix.value
        delayMixLabel.showStatus(String(format: "%.0f", value) + "%")
        delay.active = delay.active.setWetDryMix(value)
        updatePreset()
    }
}

extension EffectsController: ControllerConfiguration {
    public func establishConnections(_ router: ComponentContainer) {
        soundFonts = router.soundFonts
        activePatchManager = router.activePatchManager
        activePatchManager.subscribe(self, notifier: activePatchChange)
        delay = router.delay
        reverb = router.reverb
    }
}

extension EffectsController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { Reverb.roomNames.count }
}

extension EffectsController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        os_log(.info, log: log, "new reverb room: %d", Reverb.roomPresets[row].rawValue)
        reverb.active = reverb.active.setPreset(row)
        updatePreset()
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.init(name: "Eurostile", size: 17.0)
            pickerLabel?.textAlignment = .center
        }

        pickerLabel?.attributedText = NSAttributedString(string: Reverb.roomNames[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemTeal])

        return pickerLabel!
    }
}

extension EffectsController {

    private func updatePreset() {
        guard let soundFont = activePatchManager.soundFont else { return }
        guard let preset = activePatchManager.patch else { return }
        let delayConfig = Settings.instance.delayGlobal ? preset.delayConfig : (delay.active.enabled ? delay.active : nil)
        let reverbConfig = Settings.instance.delayGlobal ? preset.reverbConfig : (reverb.active.enabled ? reverb.active : nil)
        soundFonts.setEffects(key: soundFont.key, index: preset.soundFontIndex, delay: delayConfig, reverb: reverbConfig)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        guard case .active = event else { return }
        guard let patch = activePatchManager.patch else { return }

        if !Settings.instance.reverbGlobal {
            if let reverbConfig = patch.reverbConfig {
                update(config: reverbConfig)
            }
            else {
                updateReverbState(false)
            }
        }

        if !Settings.instance.delayGlobal {
            if let delayConfig = patch.delayConfig {
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
        updateReverbState(config.enabled)
    }

    private func updateReverbState(_ enabled: Bool) {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear)
        animator.addAnimations {
            self.reverbEnabled.showEnabled(enabled)
            self.reverbGlobal.isEnabled = true
            self.reverbGlobal.isUserInteractionEnabled = true
            self.reverbControls.alpha = self.alpha(for: enabled)
            self.reverbWetDryMix.isEnabled = enabled
            self.reverbRoom.isUserInteractionEnabled = enabled
        }
        animator.startAnimation()
    }

    private func update(config: DelayConfig) {
        delayTime.setValue(config.time, animated: true)
        delayFeedback.setValue(config.feedback, animated: true)
        delayCutoff.setValue(config.cutoff, animated: true)
        delayWetDryMix.setValue(config.wetDryMix, animated: true)
        updateDelayState(config.enabled)
    }

    private func updateDelayState(_ enabled: Bool) {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear)
        animator.addAnimations {
            self.delayEnabled.showEnabled(enabled)
            self.delayGlobal.isEnabled = true
            self.delayGlobal.isUserInteractionEnabled = true
            self.delayControls.alpha = self.alpha(for: enabled)
            self.delayWetDryMix.isEnabled = enabled
            self.delayTime.isEnabled = enabled
            self.delayFeedback.isEnabled = enabled
            self.delayCutoff.isEnabled = enabled
        }
        animator.startAnimation()
    }

    private func showReverbMixValue() { reverbMixLabel.showStatus(String(format: "%.0f", reverbWetDryMix.value) + "%") }
    private func showDelayTime() { delayTimeLabel.showStatus(String(format: "%.2f", delayTime.value) + "s") }
    private func showDelayFeedback() { delayFeedbackLabel.showStatus(String(format: "%.0f", delayFeedback.value) + "%") }
    private func showDelayCutoff() {
        if delayCutoff.value < 1000.0 {
            delayCutoffLabel.showStatus(String(format: "%.1f", delayCutoff.value) + " Hz")
        }
        else {
            delayCutoffLabel.showStatus(String(format: "%.2f", delayCutoff.value / 1000.0) + " kHz")
        }
    }
    private func showDelayMixValue() { delayMixLabel.showStatus(String(format: "%.0f", delayWetDryMix.value) + "%") }
}
