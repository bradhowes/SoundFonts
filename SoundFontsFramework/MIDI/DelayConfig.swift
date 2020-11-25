// Copyright © 2020 Brad Howes. All rights reserved.

public struct DelayConfig: Codable {
    public let enabled: Bool
    public let time: Float
    public let feedback: Float
    public let cutoff: Float
    public let wetDryMix: Float

    public init() {
        enabled = false
        time = 1.0
        feedback = 50.0
        cutoff = 15000.0
        wetDryMix = 35.0
    }

    public init(time: Float, feedback: Float, cutoff: Float, wetDryMix: Float) {
        enabled = true
        self.time = time
        self.feedback = feedback
        self.cutoff = cutoff
        self.wetDryMix = wetDryMix
    }
}

extension DecodableDefault.Sources {
    enum DefaultDelayConfig: DecodableDefaultSource {
        public static var defaultValue: DelayConfig { DelayConfig() }
    }
}

extension DecodableDefault {
    typealias DefaultDelayConfig = Wrapper<Sources.DefaultDelayConfig>
}
