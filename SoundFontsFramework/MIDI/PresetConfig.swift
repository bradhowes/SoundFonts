// Copyright © 2021 Brad Howes. All rights reserved.

public struct PresetConfig: Codable {
    public typealias ChangedNotification = TypedNotification<PresetConfig>

    /// Notification that will be emitted when the persistent container is available to use.
    public static let changedNotification: ChangedNotification = ChangedNotification(name: .presetConfigChanged)

    /// The starting note of the keyboard.
    public var keyboardLowestNote: Note?

    /// If true, then update the keyboard when the preset is activated
    public var keyboardLowestNoteEnabled: Bool = false

    /// Gain applied to sampler output. Valid values [-90..+12] with default 0.0 See doc for `AVAudioUnitSampler`
    public var gain: Float = 0.0

    /// Stereo panning applied to sampler output. Valid values [-100..+100] with default 0.0. See doc for
    /// `AVAudioUnitSampler`
    public var pan: Float = 0.0

    /// Current preset tuning value (cents)
    public var presetTuning: Float = 0.0
    public var presetTuningEnabled: Bool = false
}
