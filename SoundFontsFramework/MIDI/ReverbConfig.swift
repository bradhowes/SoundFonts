// Copyright © 2020 Brad Howes. All rights reserved.

public struct ReverbConfig: Codable {
    public let enabled: Bool
    public let room: Int
    public let wetDryMix: Float

    public init() {
        enabled = false
        room = 1
        wetDryMix = 35.0
    }

    public init(room: Int, wetDryMix: Float) {
        enabled = true
        self.room = room
        self.wetDryMix = wetDryMix
    }
}

extension DecodableDefault.Sources {
    enum DefaultReverbConfig: DecodableDefaultSource {
        public static var defaultValue: ReverbConfig { ReverbConfig() }
    }
}

extension DecodableDefault {
    typealias DefaultReverbConfig = Wrapper<Sources.DefaultReverbConfig>
}
