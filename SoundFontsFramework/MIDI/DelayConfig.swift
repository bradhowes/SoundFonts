// Copyright © 2020 Brad Howes. All rights reserved.

public class DelayConfig: NSObject, Codable {

    public let enabled: Bool
    public let time: Float
    public let feedback: Float
    public let cutoff: Float
    public let wetDryMix: Float

    public init(enabled: Bool, time: Float, feedback: Float, cutoff: Float, wetDryMix: Float) {
        self.enabled = enabled
        self.time = time
        self.feedback = feedback
        self.cutoff = cutoff
        self.wetDryMix = wetDryMix
        super.init()
    }

    public convenience override init() {
        self.init(enabled: false, time: settings.delayTime, feedback: settings.delayFeedback, cutoff: settings.delayCutoff, wetDryMix: settings.delayWetDryMix)
    }

    public func toggleEnabled() -> DelayConfig { setEnabled(!enabled) }

    func setEnabled(_ enabled: Bool) -> DelayConfig { DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix) }
    func setTime(_ time: Float) -> DelayConfig { DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix) }
    func setFeedback(_ feedback: Float) -> DelayConfig { DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix) }
    func setCutoff(_ cutoff: Float) -> DelayConfig { DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix) }
    func setWetDryMix(_ wetDryMix: Float) -> DelayConfig { DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix) }
}

extension DelayConfig {
    public override var description: String { "<Delay \(enabled) \(time) \(cutoff) \(wetDryMix)>" }
}
