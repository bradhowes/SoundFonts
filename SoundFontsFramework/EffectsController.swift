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
    private var observers = [NSKeyValueObservation]()

    public override func viewDidLoad() {
        reverbRoom.dataSource = self
        reverbRoom.delegate = self
        reverbRoom.selectRow(settings.reverbPreset, inComponent: 0, animated: false)
        reverbWetDryMix.value = settings.reverbWetDryMix
        updateReverbState(settings.reverbEnabled)

        delayTime.value = settings.delayTime
        delayFeedback.value = settings.delayFeedback
        delayCutoff.value = settings.delayCutoff
        delayWetDryMix.value = settings.delayWetDryMix
        updateDelayState(settings.delayEnabled)
    }

    @IBAction func toggleReverbEnabled(_ sender: UIButton) {
        let enabled = !reverbWetDryMix.isEnabled
        updateReverbState(enabled)
        if let reverb = self.reverb {
            reverb.active = reverb.active.setEnabled(enabled)
        }
    }

    @IBAction func toggleReverbGlobal(_ sender: UIButton) {
        let value = !settings.reverbGlobal
        reverbGlobal.showEnabled(value)
        settings.reverbGlobal = value
    }

    @IBAction func toggleDelayEnabled(_ sender: UIButton) {
        let enabled = !delayWetDryMix.isEnabled
        updateDelayState(enabled)
        if let delay = self.delay {
            delay.active = delay.active.setEnabled(enabled)
        }
    }

    @IBAction func toggleDelayGlobal(_ sender: UIButton) {
        let value = !settings.delayGlobal
        delayGlobal.showEnabled(value)
        settings.delayGlobal = value
    }

    @IBAction func changeReverbWebDryMix(_ sender: Any) {
        let value = reverbWetDryMix.value
        reverbMixLabel.showStatus(String(format: "%.0f", value) + "%")
        reverb.active = reverb.active.setWetDryMix(value)
    }

    @IBAction func changeDelayTime(_ sender: Any) {
        let value = delayTime.value
        delayTimeLabel.showStatus(String(format: "%.2f", value) + "s")
        delay.active = delay.active.setTime(value)
    }

    @IBAction func changeDelayFeedback(_ sender: Any) {
        let value = delayFeedback.value
        delayFeedbackLabel.showStatus(String(format: "%.0f", value) + "%")
        delay.active = delay.active.setFeedback(value)
    }

    @IBAction func changeDelayCutoff(_ sender: Any) {
        let value = delayCutoff.value
        if value < 1000.0 {
            delayCutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
        }
        else {
            delayCutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
        }
        delay.active = delay.active.setCutoff(value)
    }

    @IBAction func changeDelayWetDryMix(_ sender: Any) {
        let value = delayWetDryMix.value
        delayMixLabel.showStatus(String(format: "%.0f", value) + "%")
        delay.active = delay.active.setWetDryMix(value)
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
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.init(name: "Eurostile", size: 15.0)
            pickerLabel?.textAlignment = .center
        }

        pickerLabel?.attributedText = NSAttributedString(string: Reverb.roomNames[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemTeal])

        return pickerLabel!
    }
}

extension EffectsController: ControllerConfiguration {
    public func establishConnections(_ router: ComponentContainer) {

        if let delay = router.delay {
            self.delay = delay
            observers.append(delay.observe(\.active, options: .new) { _, change in
                guard let newValue = change.newValue, settings.delayGlobal == false else { return }
                DispatchQueue.main.async { self.update(config: newValue) }
            })
        }

        if let reverb = router.reverb {
            self.reverb = reverb
            observers.append(reverb.observe(\.active, options: .new) { _, change in
                guard let newValue = change.newValue, settings.reverbGlobal == false else { return }
                DispatchQueue.main.async { self.update(config: newValue) }
            })
        }
    }
}

extension EffectsController {

    private func update(config: ReverbConfig) {
        reverbWetDryMix.value = config.wetDryMix
        updateReverbState(config.enabled)
    }

    private func updateReverbState(_ enabled: Bool) {
        reverbEnabled.showEnabled(enabled)
        reverbControls.alpha = enabled ? 1.0 : 0.5
        reverbWetDryMix.isEnabled = enabled
        reverbRoom.isUserInteractionEnabled = enabled
    }

    private func update(config: DelayConfig) {
        delayTime.value = config.time
        delayFeedback.value = config.feedback
        delayCutoff.value = config.cutoff
        delayWetDryMix.value = config.wetDryMix
        updateDelayState(config.enabled)
    }

    private func updateDelayState(_ enabled: Bool) {
        delayEnabled.showEnabled(enabled)
        delayControls.alpha = enabled ? 1.0 : 0.5
        delayWetDryMix.isEnabled = enabled
        delayTime.isEnabled = enabled
        delayFeedback.isEnabled = enabled
        delayCutoff.isEnabled = enabled
    }

}
