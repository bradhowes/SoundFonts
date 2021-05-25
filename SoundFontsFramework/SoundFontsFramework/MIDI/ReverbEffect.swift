// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation

/**
 Reverberation audio effect by way of Apple's AVAudioUnitReverb component.
 */
public final class ReverbEffect: NSObject {

    public let audioUnit = AVAudioUnitReverb()

    private let _factoryPresetDefs = [
        PresetEntry(name: "Metallic Taste",
                    config: ReverbConfig(enabled: true, preset: ReverbEffect.roomPresets.firstIndex(of: .plate)!,
                                         wetDryMix: 100)),
        PresetEntry(name: "Shower",
                    config: ReverbConfig(enabled: true, preset: ReverbEffect.roomPresets.firstIndex(of: .smallRoom)!,
                                         wetDryMix: 60)),
        PresetEntry(name: "Bedroom",
                    config: ReverbConfig(enabled: true, preset: ReverbEffect.roomPresets.firstIndex(of: .mediumRoom)!,
                                         wetDryMix: 40)),
        PresetEntry(name: "Church",
                    config: ReverbConfig(enabled: true, preset: ReverbEffect.roomPresets.firstIndex(of: .cathedral)!,
                                         wetDryMix: 30))
    ]

    public lazy var factoryPresetConfigs: [ReverbConfig] = _factoryPresetDefs.map { $0.config }
    public lazy var factoryPresets: [AUAudioUnitPreset] = _factoryPresetDefs.enumerated().map {
        AUAudioUnitPreset(number: $0.offset, name: $0.element.name)
    }

    public var active: ReverbConfig { didSet { applyActiveConfig(self.active) } }

    public static let roomNames = [
        "Room 1", // smallRoom
        "Room 2", // mediumRoom
        "Room 3", // largeRoom
        "Room 4", // largeRoom2
        "Hall 1", // mediumHall
        "Hall 2", // mediumHall2
        "Hall 3", // mediumHall3
        "Hall 4", // largeHall
        "Hall 5", // largeHall2
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
        self.active = ReverbConfig(enabled: true, preset: ReverbEffect.roomPresets.firstIndex(of: .smallRoom)!,
                                   wetDryMix: 30.0)
        super.init()
        applyActiveConfig(self.active)
    }
}

extension ReverbEffect {

    private func applyActiveConfig(_ config: ReverbConfig) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.audioUnit.loadFactoryPreset(ReverbEffect.roomPresets[config.preset])
            self.audioUnit.wetDryMix = config.enabled ? config.wetDryMix : 0.0
        }
    }
}
