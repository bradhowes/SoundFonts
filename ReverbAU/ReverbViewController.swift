// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class ReverbViewController: AUViewController {
    private let log = Logging.logger("ReverbVC")
    let reverb = Reverb()
    var audioUnit: ReverbAU?

    @IBOutlet private weak var enabledButton: UIButton!
    @IBOutlet private weak var enabledLED: UIView!
    @IBOutlet private weak var controls: UIStackView!
    @IBOutlet private weak var wetDryMix: Knob!
    @IBOutlet private weak var mixLabel: UILabel!
    @IBOutlet private weak var room: UIPickerView!

    public override func viewDidLoad() {
        os_log(.info, log: log, "viewDidLoad")
        super.viewDidLoad()

        room.dataSource = self
        room.delegate = self
        room.selectRow(settings.reverbPreset, inComponent: 0, animated: false)
        wetDryMix.value = settings.reverbWetDryMix

        updateReverbState(true)
    }

    @IBAction func changWetDryMix(_ sender: Any) {
        let value = wetDryMix.value
        mixLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.reverbWetDryMix = value
    }

    @IBAction func toggleEnabled(_ sender: UIButton) {
        let enabled = !wetDryMix.isEnabled
        updateReverbState(enabled)
    }
}

extension ReverbViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try ReverbAU(componentDescription: componentDescription, reverb: reverb)
        os_log(.info ,log: log, "created ReverbAU")
        self.audioUnit = audioUnit
        return audioUnit
    }
}

extension ReverbViewController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { Reverb.roomNames.count }
}

extension ReverbViewController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        os_log(.info, log: log, "new reverb room: %d", Reverb.roomPresets[row].rawValue)
        settings.reverbPreset = Reverb.roomPresets[row].rawValue
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 15.0)
            pickerLabel?.textAlignment = .center
        }

        pickerLabel?.attributedText = NSAttributedString(string: Reverb.roomNames[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemTeal])

        return pickerLabel!
    }
}

extension ReverbViewController {

    private func updateReverbState(_ enabled: Bool) {
        enabledLED.backgroundColor = enabled ? .systemGreen  : .darkGray
        controls.alpha = enabled ? 1.0 : 0.5
        wetDryMix.isEnabled = enabled
        room.isUserInteractionEnabled = enabled
        settings.reverbEnabled = enabled
    }
}
