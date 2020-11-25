// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

/**
 Reverberation audio effect by way of Apple's AVAudioUnitReverb component. Configuration of the reverb is maintained in UserDefaults so this is only useful in the application
 setting -- the AUv3 app extension component relies on AUv3 presets to do this instead.
 */
public final class Reverb {
    private lazy var log = Logging.logger("Reverb")

    public let audioUnit: AVAudioUnitReverb
    private var observers = [NSKeyValueObservation]()

    public static let roomNames = [
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

    public static let roomPresets: [AVAudioUnitReverbPreset] = [
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

    public init() {
        self.audioUnit = AVAudioUnitReverb()

        observers.append(settings.observe(\.reverbPreset, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "preset: %d", newValue)
            self.updatePreset(newValue: newValue)
        })

        observers.append(settings.observe(\.reverbWetDryMix, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "wetDry: %f", newValue)
            self.updateWetDryMix(newValue: newValue)
        })

        observers.append(settings.observe(\.reverbEnabled, options: .new) { _, change in
            guard let newValue = change.newValue else { return }
            os_log(.info, log: self.log, "enabled: %d", newValue)
            self.updateEnabled(newValue: newValue)
        })

        updatePreset(newValue: settings.reverbPreset)
        updateWetDryMix(newValue: settings.reverbWetDryMix)
        updateEnabled(newValue: settings.reverbEnabled)
    }

    public func configure(_ config: ReverbConfig) {
        updateEnabled(newValue: config.enabled)
        updatePreset(newValue: config.room)
        updateWetDryMix(newValue: config.wetDryMix)
    }
}

extension Reverb {

    private func updateEnabled(newValue: Bool) {
        audioUnit.wetDryMix = newValue ? settings.reverbWetDryMix : 0.0
    }

    private func updatePreset(newValue: Int) {
        guard let preset = AVAudioUnitReverbPreset(rawValue: newValue) else { fatalError("invalid preseet enum value - \(newValue)") }
        audioUnit.loadFactoryPreset(preset)
    }

    private func updateWetDryMix(newValue: Float) {
        audioUnit.wetDryMix = newValue
    }
}
