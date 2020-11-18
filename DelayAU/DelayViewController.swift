// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class DelayViewController: AUViewController {
    private let log = Logging.logger("DelayVC")
    let delay = Delay()
    var audioUnit: DelayAU?

    @IBOutlet weak var enabledLED: UIView!
    @IBOutlet weak var enabledButton: UIButton!
    @IBOutlet weak var controls: UIStackView!
    @IBOutlet weak var time: Knob!
    @IBOutlet weak var feedback: Knob!
    @IBOutlet weak var cutoff: Knob!
    @IBOutlet weak var wetDryMix: Knob!
    @IBOutlet weak var valueLabel: UILabel!
    
    public override func viewDidLoad() {
        os_log(.info, log: log, "viewDidLoad")
        super.viewDidLoad()

        time.value = settings.delayTime
        feedback.value = settings.delayFeedback
        cutoff.value = settings.delayCutoff
        wetDryMix.value = settings.delayWetDryMix
        updateDelayState(settings.delayEnabled)
    }

    @IBAction func toggleDelayEnabled(_ sender: UIButton) {
        let enabled = !wetDryMix.isEnabled
        updateDelayState(enabled)
    }

    @IBAction func changeDelayTime(_ sender: Any) {
        let value = time.value
        settings.delayTime = value
    }

    @IBAction func changeDelayFeedback(_ sender: Any) {
        let value = feedback.value
        settings.delayFeedback = value
    }

    @IBAction func changeDelayCutoff(_ sender: Any) {
        let value = cutoff.value
        settings.delayCutoff = value
    }

    @IBAction func changeDelayWebDryMix(_ sender: Any) {
        let value = wetDryMix.value
        settings.delayWetDryMix = value
    }
}

extension DelayViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try DelayAU(componentDescription: componentDescription, delay: delay)
        os_log(.info ,log: log, "created ReverbAU")
        self.audioUnit = audioUnit
        return audioUnit
    }
}

extension DelayViewController {

    private func updateDelayState(_ enabled: Bool) {
        enabledLED.backgroundColor = enabled ? .systemGreen  : .darkGray
        controls.alpha = enabled ? 1.0 : 0.5
        wetDryMix.isEnabled = enabled
        time.isEnabled = enabled
        feedback.isEnabled = enabled
        cutoff.isEnabled = enabled
        settings.delayEnabled = enabled
    }
}
