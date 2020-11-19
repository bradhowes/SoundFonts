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
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var feedback: Knob!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var cutoff: Knob!
    @IBOutlet weak var cutoffLabel: UILabel!
    @IBOutlet weak var wetDryMix: Knob!
    @IBOutlet weak var wetDryMixLabel: UILabel!

    public override func viewDidLoad() {
        os_log(.info, log: log, "viewDidLoad")
        super.viewDidLoad()

        time.value = settings.delayTime
        feedback.value = settings.delayFeedback
        cutoff.value = settings.delayCutoff
        wetDryMix.value = settings.delayWetDryMix
        updateEnabledState(true)
    }

    @IBAction func toggleEnabled(_ sender: UIButton) {
        let enabled = !wetDryMix.isEnabled
        updateEnabledState(enabled)
    }

    @IBAction func changeTime(_ sender: Any) {
        let value = time.value
        timeLabel.showStatus(String(format: "%.2f", value) + "s")
        settings.delayTime = value
    }

    @IBAction func changeFeedback(_ sender: Any) {
        let value = feedback.value
        feedbackLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.delayFeedback = value
    }

    @IBAction func changeCutoff(_ sender: Any) {
        let value = cutoff.value
        if value < 1000.0 {
            cutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
        }
        else {
            cutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
        }
        settings.delayCutoff = value
    }

    @IBAction func changeWebDryMix(_ sender: Any) {
        let value = wetDryMix.value
        wetDryMixLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.delayWetDryMix = value
    }
}

extension DelayViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try DelayAU(componentDescription: componentDescription, delay: delay)
        os_log(.info ,log: log, "created DelayAU")
        self.audioUnit = audioUnit
        return audioUnit
    }
}

extension DelayViewController {

    private func updateEnabledState(_ enabled: Bool) {
        enabledLED.backgroundColor = enabled ? .systemGreen  : .darkGray
        controls.alpha = enabled ? 1.0 : 0.5
        time.isEnabled = enabled
        feedback.isEnabled = enabled
        cutoff.isEnabled = enabled
        wetDryMix.isEnabled = enabled
        settings.delayEnabled = enabled
    }
}

extension UIView {

    func fadeTransition(duration: CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.type = .fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
