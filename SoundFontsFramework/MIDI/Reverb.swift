// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

public final class Reverb {
    private lazy var log = Logging.logger("Reverb")

    public let reverb: AVAudioUnitReverb
    private var observers = [NSKeyValueObservation]()

    public init() {
        self.reverb = AVAudioUnitReverb()
        observers.append(settings.observe(\.reverbPreset, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            self.updatePreset(newValue: newValue)
        })

        observers.append(settings.observe(\.reverbMix, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            self.updateWetDryMix(newValue: newValue)
        })
    }
}

extension Reverb {

    private func updatePreset(newValue: Int) {
        if newValue == -1 {
            reverb.bypass = true
            return
        }

        guard let preset = AVAudioUnitReverbPreset(rawValue: newValue) else { fatalError("invalid preseet enum value - \(newValue)") }
        reverb.bypass = true
        reverb.loadFactoryPreset(preset)
    }

    private func updateWetDryMix(newValue: Float) {
        reverb.wetDryMix = newValue
    }
}
