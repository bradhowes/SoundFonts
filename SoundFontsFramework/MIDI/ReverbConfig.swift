// Copyright © 2020 Brad Howes. All rights reserved.

public class ReverbConfig: NSObject, Codable {

    public let enabled: Bool
    public let preset: Int
    public let wetDryMix: Float

    public init(enabled: Bool, preset: Int, wetDryMix: Float) {
        self.enabled = enabled
        self.preset = preset
        self.wetDryMix = wetDryMix
        super.init()
    }

    public convenience override init() {
        self.init(enabled: false, preset: Settings.instance.reverbPreset, wetDryMix: Settings.instance.delayWetDryMix)
    }

    public func toggleEnabled() -> ReverbConfig { setEnabled(!enabled) }

    func setEnabled(_ enabled: Bool) -> ReverbConfig { ReverbConfig(enabled: enabled, preset: preset, wetDryMix: wetDryMix) }
    func setPreset(_ preset: Int) -> ReverbConfig { ReverbConfig(enabled: enabled, preset: preset, wetDryMix: wetDryMix) }
    func setWetDryMix(_ wetDryMix: Float) -> ReverbConfig { ReverbConfig(enabled: enabled, preset: preset, wetDryMix: wetDryMix) }
}

extension ReverbConfig {
    public override var description: String { "<Reverb \(enabled) \(Reverb.roomNames[preset]) \(wetDryMix)>" }
}
