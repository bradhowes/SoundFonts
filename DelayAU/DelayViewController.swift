// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class DelayViewController: AUViewController {
    private let log = Logging.logger("DelayVC")
    private var audioUnit: DelayAU?
    private var parameterObserverToken: AUParameterObserverToken?

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
        updateState(true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        if audioUnit != nil && parameterObserverToken == nil { connectAU() }
    }

    @IBAction func changeTime(_ sender: Any) { setTime(value: time.value) }
    @IBAction func changeFeedback(_ sender: Any) { setFeedback(value: feedback.value) }
    @IBAction func changeCutoff(_ sender: Any) { setCutoff(value: cutoff.value) }
    @IBAction func changeWebDryMix(_ sender: Any) { setWetDryMix(value: wetDryMix.value) }
    @IBAction func toggleEnabled(_ sender: UIButton) {
        settings.delayEnabled = !settings.delayEnabled
        updateState(!wetDryMix.isEnabled)
    }
}

extension DelayViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try DelayAU(componentDescription: componentDescription)
        os_log(.info ,log: log, "created DelayAU")
        self.audioUnit = audioUnit
        return audioUnit
    }
}

extension DelayViewController {

    private func connectAU() {

        guard let audioUnit = audioUnit else { fatalError("nil audioUnit") }
        guard let parameterTree = audioUnit.parameterTree else { fatalError("nil parameterTree") }

        guard let time = parameterTree.parameter(withAddress: AudioUnitParameters.Address.time.rawValue) else { fatalError("Undefined time parameter") }
        guard let feedback = parameterTree.parameter(withAddress: AudioUnitParameters.Address.feedback.rawValue) else { fatalError("Undefined feedback parameter") }
        guard let cutoff = parameterTree.parameter(withAddress: AudioUnitParameters.Address.cutoff.rawValue) else { fatalError("Undefined cutoff parameter") }
        guard let wetDryMix = parameterTree.parameter(withAddress: AudioUnitParameters.Address.wetDryMix.rawValue) else { fatalError("Undefined wetDryMix parameter") }

        setTime(value: time.value)
        setFeedback(value: feedback.value)
        setCutoff(value: cutoff.value)
        setWetDryMix(value: wetDryMix.value)

        parameterObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, value in
            guard let self = self else { return }
            switch address {
            case AudioUnitParameters.Address.time.rawValue: DispatchQueue.main.async { self.setTime(value: value) }
            case AudioUnitParameters.Address.feedback.rawValue: DispatchQueue.main.async { self.setFeedback(value: value) }
            case AudioUnitParameters.Address.cutoff.rawValue: DispatchQueue.main.async { self.setCutoff(value: value) }
            case AudioUnitParameters.Address.wetDryMix.rawValue: DispatchQueue.main.async { self.setWetDryMix(value: value) }
            default: break
            }
        })
    }

    private func setTime(value: AUValue) {
        time.value = min(max(value, 0.0), 2.0)
        timeLabel.showStatus(String(format: "%.2f", value) + "s")
        settings.delayTime = value
    }

    private func setFeedback(value: AUValue) {
        feedback.value = min(max(value, -100.0), 100.0)
        feedbackLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.delayFeedback = value
    }

    private func setCutoff(value: AUValue) {
        cutoff.value = min(max(value, 10.0), 20_000.0)
        if value < 1000.0 {
            cutoffLabel.showStatus(String(format: "%.1f", value) + " Hz")
        }
        else {
            cutoffLabel.showStatus(String(format: "%.2f", value / 1000.0) + " kHz")
        }
        settings.delayCutoff = value
    }

    private func setWetDryMix(value: AUValue) {
        wetDryMix.value = min(max(value, 0.0), 100.0)
        wetDryMixLabel.showStatus(String(format: "%.0f", value) + "%")
        settings.delayWetDryMix = value
    }

    private func updateState(_ enabled: Bool) {
        controls.alpha = enabled ? 1.0 : 0.5
        time.isEnabled = enabled
        feedback.isEnabled = enabled
        cutoff.isEnabled = enabled
        wetDryMix.isEnabled = enabled
        enabledButton.showEnabled(enabled)
    }
}
