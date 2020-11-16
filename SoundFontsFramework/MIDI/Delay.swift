// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

/**
 Delay audio effect.
 */
public final class Delay {
    private lazy var log = Logging.logger("Delay")

    public let audioUnit: AVAudioUnitDelay
    private var observers = [NSKeyValueObservation]()

    public init() {
        self.audioUnit = AVAudioUnitDelay()

        observers.append(settings.observe(\.delayTime, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "time: %d", newValue)
            self.updateTime(newValue: newValue)
        })

        observers.append(settings.observe(\.delayFeedback, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "feedback: %d", newValue)
            self.updateFeedback(newValue: newValue)
        })

        observers.append(settings.observe(\.delayCutoff, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "feedback: %d", newValue)
            self.updateCutoff(newValue: newValue)
        })

        observers.append(settings.observe(\.delayWetDryMix, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "wetDry: %f", newValue)
            self.updateWetDryMix(newValue: newValue)
        })

        observers.append(settings.observe(\.delayEnabled, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "enabled: %d", newValue)
            self.updateEnabled(newValue: newValue)
        })

        updateEnabled(newValue: settings.delayEnabled)
        updateTime(newValue: settings.delayTime)
        updateFeedback(newValue: settings.delayFeedback)
        updateCutoff(newValue: settings.delayCutoff)
        updateWetDryMix(newValue: settings.delayWetDryMix)
    }
}

extension Delay {

    private func updateEnabled(newValue: Bool) {
        audioUnit.wetDryMix = newValue ? settings.delayWetDryMix : 0.0
    }

    private func updateTime(newValue: Float) {
        audioUnit.delayTime = Double(newValue)
    }

    private func updateFeedback(newValue: Float) {
        audioUnit.feedback = newValue
    }

    private func updateCutoff(newValue: Float) {
        audioUnit.lowPassCutoff = newValue
    }

    private func updateWetDryMix(newValue: Float) {
        audioUnit.wetDryMix = newValue
    }
}
