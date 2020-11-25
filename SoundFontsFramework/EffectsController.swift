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

    @IBOutlet weak var reverbEnabledLED: UIView!
    @IBOutlet weak var reverbEnabled: UIButton!
    @IBOutlet weak var reverbControls: UIStackView!
    @IBOutlet weak var reverbWetDryMix: Knob!
    @IBOutlet weak var reverbMixLabel: UILabel!
    @IBOutlet weak var reverbRoom: UIPickerView!

    @IBOutlet weak var delayEnabledLED: UIView!
    @IBOutlet weak var delayEnabled: UIButton!
    @IBOutlet weak var delayControls: UIStackView!
    @IBOutlet weak var delayTime: Knob!
    @IBOutlet weak var delayTimeLabel: UILabel!
    @IBOutlet weak var delayFeedback: Knob!
    @IBOutlet weak var delayFeedbackLabel: UILabel!
    @IBOutlet weak var delayCutoff: Knob!
    @IBOutlet weak var delayCutoffLabel: UILabel!
    @IBOutlet weak var delayWetDryMix: Knob!
    @IBOutlet weak var delayMixLabel: UILabel!

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
    }

    private func updateReverbState(_ enabled: Bool) {
        reverbEnabledLED.backgroundColor = enabled ? .systemGreen  : .darkGray
        reverbControls.alpha = enabled ? 1.0 : 0.5
        reverbWetDryMix.isEnabled = enabled
        reverbRoom.isUserInteractionEnabled = enabled
        settings.reverbEnabled = enabled
    }

    @IBAction func toggleDelayEnabled(_ sender: UIButton) {
        let enabled = !delayWetDryMix.isEnabled
        updateDelayState(enabled)
    }

    private func updateDelayState(_ enabled: Bool) {
        delayEnabledLED.backgroundColor = enabled ? .systemGreen  : .darkGray
        delayControls.alpha = enabled ? 1.0 : 0.5
        delayWetDryMix.isEnabled = enabled
        delayTime.isEnabled = enabled
        delayFeedback.isEnabled = enabled
        delayCutoff.isEnabled = enabled
        settings.delayEnabled = enabled
    }

    @IBAction func changeReverbWebDryMix(_ sender: Any) {
        let value = reverbWetDryMix.value
        reverbMixLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.reverbWetDryMix = value
    }

    @IBAction func changeDelayTime(_ sender: Any) {
        let value = delayTime.value
        delayTimeLabel.showStatus(String(format: "%.2f", value) + "s")
        settings.delayTime = value
    }

    @IBAction func changeDelayFeedback(_ sender: Any) {
        let value = delayFeedback.value
        delayFeedbackLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.delayFeedback = value
    }

    @IBAction func changeDelayCutoff(_ sender: Any) {
        let value = delayCutoff.value
        if value < 1000.0 {
            delayCutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
        }
        else {
            delayCutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
        }
        settings.delayCutoff = value
    }

    @IBAction func changeDelayWebDryMix(_ sender: Any) {
        let value = delayWetDryMix.value
        delayMixLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.delayWetDryMix = value
    }
}

extension EffectsController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { Reverb.roomNames.count }
}

extension EffectsController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        os_log(.info, log: log, "new reverb room: %d", Reverb.roomPresets[row].rawValue)
        settings.reverbPreset = Reverb.roomPresets[row].rawValue
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
    }
}
