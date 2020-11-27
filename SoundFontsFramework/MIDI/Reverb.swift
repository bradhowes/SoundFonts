// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import AVFoundation
import AudioToolbox
import os

/**
 Reverberation audio effect by way of Apple's AVAudioUnitReverb component. Configuration of the reverb is maintained in UserDefaults so this is only useful in the application
 setting -- the AUv3 app extension component relies on AUv3 presets to do this instead.
 */
public final class Reverb: NSObject {
    private lazy var log = Logging.logger("Reverb")

    public let audioUnit = AVAudioUnitReverb()
    public private(set) var presets = [String: ReverbConfig]()
    @objc public dynamic var active: ReverbConfig { didSet { update() } }

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

    public override init() {
        self.active = ReverbConfig(enabled: settings.reverbEnabled, preset: settings.reverbPreset, wetDryMix: settings.reverbWetDryMix)
        super.init()
        update()
    }
}

extension Reverb: ReverbEffect {

    public func savePreset(name: String, config: ReverbConfig) {
        presets[name] = config
    }

    public func removePreset(name: String) {
        presets.removeValue(forKey: name)
    }
}

extension Reverb {

    private func update() {
        // audioUnit.bypass = !active.enabled
        // audioUnit.wetDryMix = active.wetDryMix
        audioUnit.wetDryMix = active.enabled ? active.wetDryMix : 0.0
        guard let preset = AVAudioUnitReverbPreset(rawValue: active.preset) else { fatalError("invalid preseet enum value - \(active.preset)") }
        audioUnit.loadFactoryPreset(preset)
    }
}
