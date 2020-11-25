// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class ReverbViewController: AUViewController {
    private let log = Logging.logger("ReverbVC")
    private var audioUnit: ReverbAU?
    private var parameterObserverToken: AUParameterObserverToken?

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
        updateReverbState(true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        if audioUnit != nil && parameterObserverToken == nil { connectAU() }
        for family: String in UIFont.familyNames {
            print(family)
            for names: String in UIFont.fontNames(forFamilyName: family) {
                print("== \(names)")
            }
        }
    }

    @IBAction func changWetDryMix(_ sender: Any) {
        let value = wetDryMix.value
        mixLabel.showStatus(String(format: "%.0f", value) + "%")
        audioUnit?.parameters.wetDryMix.setValue(value, originator: parameterObserverToken)
    }

    @IBAction func toggleEnabled(_ sender: UIButton) {
        let enabled = !wetDryMix.isEnabled
        updateReverbState(enabled)
    }
}

extension ReverbViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try ReverbAU(componentDescription: componentDescription)
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
        audioUnit?.activeRoomPreset = row
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

extension ReverbViewController {

    private func connectAU() {

        guard let audioUnit = audioUnit else { fatalError("nil audioUnit") }
        guard let parameterTree = audioUnit.parameterTree else { fatalError("nil parameterTree") }

        guard let roomPreset = parameterTree.parameter(withAddress: AudioUnitParameters.Address.roomPreset.rawValue) else { fatalError("Undefined roomPreset parameter") }
        guard let wetDryMix = parameterTree.parameter(withAddress: AudioUnitParameters.Address.wetDryMix.rawValue) else { fatalError("Undefined wetDryMix parameter") }

        setActiveRoom(value: roomPreset.value)
        setWetDryMix(value: wetDryMix.value)

        parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self else { return }
            switch address {
            case AudioUnitParameters.Address.roomPreset.rawValue: DispatchQueue.main.async { self.setActiveRoom(value: value) }
            case AudioUnitParameters.Address.wetDryMix.rawValue: DispatchQueue.main.async { self.setWetDryMix(value: value) }
            default: break
            }
        })
    }

    private func setActiveRoom(value: AUValue) {
        let index = min(max(Int(value), 0), Reverb.roomNames.count - 1)
        room.selectRow(index, inComponent: 0, animated: true)
    }

    private func setWetDryMix(value: AUValue) {
        wetDryMix.value = min(max(value, 0.0), 100.0)
        mixLabel.showStatus(String(format: "%.0f", value) + "%")
    }

    private func updateReverbState(_ enabled: Bool) {
        enabledLED.backgroundColor = enabled ? .systemGreen  : .darkGray
        controls.alpha = enabled ? 1.0 : 0.5
        wetDryMix.isEnabled = enabled
        room.isUserInteractionEnabled = enabled
    }
}
