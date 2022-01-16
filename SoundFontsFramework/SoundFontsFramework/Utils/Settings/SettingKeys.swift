// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation

/// Container to place SettingKey definitions (as class members)
public class SettingKeys {
  internal init() {}
}

public extension SettingKeys {

  // MARK: - App / AUv3 non-shared settings. For AUv3 these are saved in fullState dictionary

  /// The last active preset (name is legacy)
  static let lastActivePreset = SettingKey("lastActivePatch", ActivePresetKind.none)
  /// The currently active sound font group tag
  static let activeTagKey = SettingKey("activeTagKey", Tag.allTag.key)
  /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
  static let showingFavorites = SettingKey("showingFavorites", false)
  /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
  static let presetsWidthMultiplier = SettingKey("presetsWidthMultiplier", 1.4)
  /// The number of semitones a max pitch bend will cause in a playing note
  static let pitchBendRangeEnabled = SettingKey("pitchBendRangeEnabled", false)
  /// The number of semitones a max pitch bend will cause in a playing note
  static let pitchBendRange = SettingKey("pitchBendRange", 2)
  /// When true, global tuning is active
  static let globalTuningEnabled = SettingKey("globalTuningEnabled", false)
  /// The global tuning setting that is in effect
  static let globalTuning = SettingKey("globalTuning", Float(0.0))
  /// When true, copy an SF2 file into the application's folder when the file is added to the app.

  // MARK: - App / AUv3 shared settings

  static let copyFilesWhenAdding = SettingKey("copyFilesWhenAdding", true)
  /// When true, the user has seen the prompt on how to restore hidden presets
  static let showedHidePresetPrompt = SettingKey("showedHidePresetPrompt", false)

  // MARK: - App-only settings (not relevant for AUv3)

  /// Current keyboard key labeling
  static let keyLabelOption = SettingKey("keyLabelOption", KeyLabelOption.cOnly.rawValue)
  /// Current keyboard key width
  static let keyWidth = SettingKey<Float>("keyWidth", 64.0)
  /// The lowest note on the keyboard that is currently visible
  static let lowestKeyNote = SettingKey("lowestKeyNote", 48)
  /// When true, play a sound when changing the active preset
  static let playSample = SettingKey("playSample", false)
  /// When true, show a solfege label when a note is played
  static let showSolfegeLabel = SettingKey("showSolfegeLabel", true)
  /// When true, allow finger movements on the keyboard to slide the keyboard to a new position
  static let slideKeyboard = SettingKey("slideKeyboard", false)
  /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
  static let showEffects = SettingKey("showEffects", false)
  /// When true, the user has viewed the tutorial pages
  static let showedTutorial = SettingKey("showedTutorial", false)
  /// When true, the user has viewed the changes page
  static let showedChanges = SettingKey("showedChanges", "")

  // MARK: - AskForReview settings

  /// The number of days to wait after the first launch of the app before asking for a review
  static let daysAfterFirstLaunchBeforeRequest = SettingKey("daysAfterFirstLaunchBeforeRequest", 14)
  /// The number of months to wait between review requests
  static let monthsAfterLastReviewBeforeRequest = SettingKey("monthsAfterLastReviewBeforeRequest", 2)
  /// The date of the first launch (not saved across reinstalls)
  static let firstLaunchDate = SettingKey("firstLaunchDate", Date.distantPast)
  /// The date of the last review request
  static let lastReviewRequestDate = SettingKey("lastReviewRequestDate", Date.distantPast)
  /// The version of the app for the last review request
  static let lastReviewRequestVersion = SettingKey("lastReviewRequestVersion", "")

  // MARK: - MIDI settings

  /// The current MIDI channel to use for incoming MIDI events. OMNI mode is a value of -1 (default).
  static let midiChannel = SettingKey("midiChannel", -1)
  /// The MIDI virtual input ID (not user settable)
  static let virtualMidiInId = SettingKey("virtualMidiInId", 0)
  /// The MIDI virtual output ID (not user settable)
  static let virtualMidiOutId = SettingKey("virtualMidiOutId", 0)

  // MARK: - Reverb settings

  /// If true, the reverb AU is currently active
  static let reverbEnabled = SettingKey("reverbEnabled", false)
  /// If true, the reverb AU is globally active
  static let reverbGlobal = SettingKey("reverbGlobal", false)
  /// The current reverb preset being used
  static let reverbPreset = SettingKey("reverbPreset", 1)
  /// The current reverb mix setting
  static let reverbWetDryMix = SettingKey("reverbWetDryMix", Float(35.0))

  // MARK: - Delay settings

  /// If true, the delay AU is currently active
  static let delayEnabled = SettingKey("delayEnabled", false)
  /// If true, the delay AU is globally active
  static let delayGlobal = SettingKey("delayGlobal", false)
  /// The current delay amount in seconds
  static let delayTime = SettingKey("delayTime", Float(0.19))
  /// The current feedback setting between -100% and 100%
  static let delayFeedback = SettingKey("delayFeedback", Float(-75.0))
  /// The current low-pass cutoff value for the delay effect
  static let delayCutoff = SettingKey("delayCutoff", Float(15000.0))
  /// The current delay mix setting
  static let delayWetDryMix = SettingKey("delayWetDryMix", Float(45.0))

  // MARK: - Chorus settings

  /// If true, the chorus AU is currently active
  static let chorusEnabled = SettingKey("chorusEnabled", false)
  /// If true, the delay AU is globally active
  static let chorusGlobal = SettingKey("chorusGlobal", false)
  /// The current delay amount in seconds
  static let chorusRate = SettingKey("chorusRate", Float(0.19))
  /// The current delay amount in seconds
  static let chorusDelay = SettingKey("chorusDelay", Float(0.19))
  /// The current delay amount in seconds
  static let chorusDepth = SettingKey("chorusDepth", Float(0.19))
  /// The current feedback setting between -100% and 100%
  static let chorusFeedback = SettingKey("chorusFeedback", Float(-75.0))
  /// The current low-pass cutoff value for the delay effect
  static let chorusCutoff = SettingKey("chorusCutoff", Float(15000.0))
  /// The current delay mix setting
  static let chorusWetDryMix = SettingKey("chorusWetDryMix", Float(45.0))
  /// If true, use negative feedback
  static let chorusNegFeedback = SettingKey("chorusNegFeedback", false)
  /// If true, the odd (R) channel is out of phase with even (L).
  static let chorusOdd90 = SettingKey("chorusOdd90", false)

  static let settingsVersion = SettingKey("settingsVersion", 0)
}
