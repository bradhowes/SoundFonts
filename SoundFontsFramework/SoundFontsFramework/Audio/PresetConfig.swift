// Copyright © 2021 Brad Howes. All rights reserved.

/**
 The configuration for a SoundFont preset. While the `Preset` struct represents a specific SoundFont preset, this
 entity holds the configuration settings for it.
 */
public struct PresetConfig: Codable {

  public typealias ChangedNotification = TypedNotification<PresetConfig>

  /// Notification that will be emitted when the persistent container is available to use.
  public static let changedNotification: ChangedNotification = ChangedNotification(name: .activePresetConfigChanged)

  /// The name for this preset configuration
  public var name: String

  /// The starting note of the keyboard.
  public var keyboardLowestNote: Note?

  /// If true, then update the keyboard when the preset is activated
  public var keyboardLowestNoteEnabled: Bool = false

  /// The reverb configuration attached to the preset (NOTE: not applicable in AUv3 extension so it is optional)
  public var reverbConfig: ReverbConfig?

  /// The delay configuration attached to the preset (NOTE: not applicable in AUv3 extension so it is optional)
  public var delayConfig: DelayConfig?

  /// The delay configuration attached to the preset (NOTE: not applicable in AUv3 extension so it is optional)
  public var chorusConfig: ChorusConfig?

  /// Range to the pitch bend controller in semi-tones (12 per octave). Default is 2.
  public var pitchBendRange: Int?

  /// Gain applied to sampler output. Valid values [-90..+12] with default 0.0 See doc for `AVAudioUnitSampler`
  public var gain: Float = 0.0

  /// Stereo panning applied to sampler output. Valid values [-100..+100] with default 0.0. See doc for
  /// `AVAudioUnitSampler`
  public var pan: Float = 0.0

  /// Current preset tuning value (cents)
  public var presetTuning: Float = 0.0

  /// User notes about the preset
  public var notes: String?

  /// True if the preset is hidden from display
  public var isHidden: Bool?

  /// True if the preset is visible in the display
  public var isVisible: Bool { (isHidden ?? false) == false }
}

extension PresetConfig: CustomStringConvertible {
  public var description: String { "<PresetConfig: \(name)>" }
}
