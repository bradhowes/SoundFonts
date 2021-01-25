// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation

public struct DelayConfig: Codable {

    public enum Key: String, CaseIterable {
        case enabled
        case time
        case feedback
        case cutoff
        case wetDryMix
    }

    public let enabled: Bool
    public let time: AUValue
    public let feedback: AUValue
    public let cutoff: AUValue
    public let wetDryMix: AUValue

    public init(enabled: Bool, time: AUValue, feedback: AUValue, cutoff: AUValue, wetDryMix: AUValue) {
        self.enabled = enabled
        self.time = time
        self.feedback = feedback
        self.cutoff = cutoff
        self.wetDryMix = wetDryMix
    }

    public init() {
        self.init(enabled: true, time: Settings.instance.delayTime, feedback: Settings.instance.delayFeedback,
                  cutoff: Settings.instance.delayCutoff, wetDryMix: Settings.instance.delayWetDryMix)
    }

    public init?(state: [String: Any]) {
        guard let enabled = state[.enabled] == 0.0 ? false : true,
              let time = state[.time],
              let feedback = state[.feedback],
              let cutoff = state[.cutoff],
              let wetDryMix = state[.wetDryMix] else { return nil }
        self.init(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix)
    }

    public func setEnabled(_ enabled: Bool) -> DelayConfig {
        DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix)
    }
    public func setTime(_ time: Float) -> DelayConfig {
        DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix)
    }
    public func setFeedback(_ feedback: Float) -> DelayConfig {
        DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix)
    }
    public func setCutoff(_ cutoff: Float) -> DelayConfig {
        DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix)
    }
    public func setWetDryMix(_ wetDryMix: Float) -> DelayConfig {
        DelayConfig(enabled: enabled, time: time, feedback: feedback, cutoff: cutoff, wetDryMix: wetDryMix)
    }

    public subscript(_ key: Key) -> AUValue {
        switch key {
        case .enabled: return AUValue(enabled ? 1.0 : 0.0)
        case .time: return time
        case .feedback: return feedback
        case .cutoff: return cutoff
        case .wetDryMix: return wetDryMix
        }
    }

    public var fullState: [String: Any] {
        [String: Any](uniqueKeysWithValues: zip(Key.allCases.map { $0.rawValue }, Key.allCases.map { self[$0] }))
    }
}

extension DelayConfig: CustomStringConvertible {
    public var description: String { "<Delay \(enabled) \(time) \(feedback) \(cutoff) \(wetDryMix)>" }
}

extension Dictionary where Key == String, Value == Any {
    fileprivate subscript(_ key: DelayConfig.Key) -> AUValue? { self[key.rawValue] as? AUValue }
}
