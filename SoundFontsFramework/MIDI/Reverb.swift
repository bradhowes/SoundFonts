// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

public final class Reverb {
    private lazy var log = Logging.logger("Reverb")

    public let audioUnit: AVAudioUnitReverb
    private var observers = [NSKeyValueObservation]()

    public init() {
        self.audioUnit = AVAudioUnitReverb()
        observers.append(settings.observe(\.reverbPreset, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "reverb preset: %d", newValue)
            self.updatePreset(newValue: newValue)
        })

        observers.append(settings.observe(\.reverbMix, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "reverb wetDry: %f", newValue)
            self.updateWetDryMix(newValue: newValue)
        })
    }
}

extension Reverb {

    private func updatePreset(newValue: Int) {
        guard let preset = AVAudioUnitReverbPreset(rawValue: newValue) else { fatalError("invalid preseet enum value - \(newValue)") }
        audioUnit.loadFactoryPreset(preset)
    }

    private func updateWetDryMix(newValue: Float) {
        audioUnit.wetDryMix = newValue
    }
}
