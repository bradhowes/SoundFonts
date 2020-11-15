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

    private let roomNames = [
        "Room 1", // smallRoom
        "Room 2", // mediumRoom
        "Room 3", // largeRoom
        "Room 4", // largeRoom2

        "Hall 1", // mediumHall
        "Hall 2", // mediumHall2
        "Hall 3", // mediumHall3
        "Hall 4", // largeHall
        "Hall 5", // largehall2

        "Chamber 1", // mediumChamber
        "Chamber 2", // largeChamber

        "Cathedral",

        "Plate"  // plate
    ]

    private let roomPresets: [AVAudioUnitReverbPreset] = [
        .smallRoom,
        .mediumRoom,
        .largeRoom,
        .largeRoom2,

        .mediumHall,
        .mediumHall2,
        .mediumHall3,
        .largeHall,
        .largeHall2,

        .mediumChamber,
        .largeChamber,

        .cathedral,

        .plate
    ]

    @IBOutlet weak var reverbEnabled: UIButton!
    @IBOutlet weak var reverbWetDryMix: Knob!
    @IBOutlet weak var reverbRoom: UIPickerView!

    @IBOutlet weak var delayEnabled: UIButton!
    @IBOutlet weak var delayTime: Knob!
    @IBOutlet weak var delayFeedback: Knob!
    @IBOutlet weak var delayCutoff: Knob!
    @IBOutlet weak var delayMix: Knob!

    private var infoBar: InfoBar?

    public override func viewDidLoad() {
        reverbRoom.dataSource = self
        reverbRoom.delegate = self
        reverbRoom.selectRow(settings.reverbPreset, inComponent: 0, animated: false)
        reverbWetDryMix.value = settings.reverbMix
    }

    @IBAction func changeReverbWebDryMix(_ sender: Any) {
        let value = reverbWetDryMix.value
        os_log(.info, log: log, "new reverb mix: %f", value)
        infoBar?.setStatus("Reverb \(value)%")
        settings.reverbMix = value
    }
}

extension EffectsController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { roomNames.count }
}

extension EffectsController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        os_log(.info, log: log, "new reverb room: %d", roomPresets[row].rawValue)
        settings.reverbPreset = roomPresets[row].rawValue
    }

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        NSAttributedString(string: roomNames[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemTeal])
    }
}

extension EffectsController: ControllerConfiguration {
    public func establishConnections(_ router: ComponentContainer) {
        self.infoBar = router.infoBar
    }
}
