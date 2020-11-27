// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

/**
 Delay audio effect.
 */
public final class Delay: NSObject {
    private lazy var log = Logging.logger("Delay")

    public let audioUnit = AVAudioUnitDelay()
    public private(set) var presets = [String: DelayConfig]()
    @objc public dynamic var active: DelayConfig {
        didSet {
            update()
        }
    }

    public override init() {
        self.active = DelayConfig(enabled: settings.delayEnabled, time: settings.delayTime, feedback: settings.delayFeedback, cutoff: settings.delayCutoff,
                                  wetDryMix: settings.delayWetDryMix)
        super.init()
        update()
    }
}

extension Delay: DelayEffect {

    public func savePreset(name: String, config: DelayConfig) {
        presets[name] = config
    }

    public func removePreset(name: String) {
        presets.removeValue(forKey: name)
    }
}

extension Delay {

    private func update() {
        audioUnit.bypass = !active.enabled
        audioUnit.wetDryMix = active.wetDryMix // active.enabled ? active.wetDryMix : 0.0
        audioUnit.delayTime = Double(active.time)
        audioUnit.feedback = active.feedback
        audioUnit.lowPassCutoff = active.cutoff
    }
}
