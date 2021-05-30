// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/// Key definitions that include the key name, the value type, and any default value associated with the setting if not
/// found
extension SettingKeys {

  // AskForReview settings

  /// The number of days to wait after the first launch of the app before asking for a review
  public static let daysAfterFirstLaunchBeforeRequest = SettingKey(
    "daysAfterFirstLaunchBeforeRequest", defaultValue: 14)
  /// The number of months to wait between review requests
  public static let monthsAfterLastReviewBeforeRequest = SettingKey(
    "monthsAfterLastReviewBeforeRequest", defaultValue: 2)
  /// The date of the first launch (not saved across reinstalls)
  public static let firstLaunchDate = SettingKey("firstLaunchDate", defaultValue: Date.distantPast)
  /// The date of the last review request
  public static let lastReviewRequestDate = SettingKey(
    "lastReviewRequestDate", defaultValue: Date.distantPast)
  /// The version of the app for the last review request
  public static let lastReviewRequestVersion = SettingKey(
    "lastReviewRequestVersion", defaultValue: "")

  // App settings

  /// Current keyboard key labeling
  public static let keyLabelOption = SettingKey(
    "keyLabelOption", defaultValue: KeyLabelOption.cOnly.rawValue)
  /// Current keyboard key width
  public static let keyWidth = SettingKey<Float>("keyWidth", defaultValue: 64.0)
  /// The last active preset/patch
  public static let lastActivePatch = SettingKey("lastActivePatch", defaultValue: Data())
  /// The lowest note on the keyboard that is currently visible
  public static let lowestKeyNote = SettingKey("lowestKeyNote", defaultValue: 48)
  /// When true, play a sound when changing the active preset
  public static let playSample = SettingKey("playSample", defaultValue: false)
  /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
  public static let showingFavorites = SettingKey("showingFavorites", defaultValue: false)
  /// When true, show a solfege label when a note is played
  public static let showSolfegeLabel = SettingKey("showSolfegeLabel", defaultValue: true)
  /// When true, copy an SF2 file into the application's folder when the file is added to the app.
  public static let copyFilesWhenAdding = SettingKey("copyFilesWhenAdding", defaultValue: true)
  /// When true, allow finger movements on the keyboard to slide the keyboard to a new position
  public static let slideKeyboard = SettingKey("slideKeyboard", defaultValue: false)

  /// The current MIDI channel to use for incoming MIDI events. OMNI mode is a value of -1 (default).
  public static let midiChannel = SettingKey("midiChannel", defaultValue: -1)
  /// The MIDI virtual destination ID (not usser settable)
  public static let midiVirtualDestinationId = SettingKey(
    "midiVirtualDestinationId", defaultValue: Int32(0))

  /// If true, the reverb AU is currently active
  public static let reverbEnabled = SettingKey("reverbEnabled", defaultValue: false)
  /// If true, the reverb AU is globally active
  public static let reverbGlobal = SettingKey("reverbGlobal", defaultValue: false)
  /// The current reverb preset being used
  public static let reverbPreset = SettingKey("reverbPreset", defaultValue: 1)
  /// The current reverb mix setting
  public static let reverbWetDryMix = SettingKey("reverbWetDryMix", defaultValue: Float(35.0))

  /// If true, the delay AU is currently active
  public static let delayEnabled = SettingKey("delayEnabled", defaultValue: false)
  /// If true, the delay AU is globally active
  public static let delayGlobal = SettingKey("delayGlobal", defaultValue: false)
  /// The current delay amount in seconds
  public static let delayTime = SettingKey("delayTime", defaultValue: Float(0.19))
  /// The current feedback setting between -100% and 100%
  public static let delayFeedback = SettingKey("delayFeedback", defaultValue: Float(-75.0))
  /// The current low-pass cutoff value for the delay effect
  public static let delayCutoff = SettingKey("delayCutoff", defaultValue: Float(15000.0))
  /// The current delay mix setting
  public static let delayWetDryMix = SettingKey("delayWetDryMix", defaultValue: Float(45.0))

  /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
  public static let showEffects = SettingKey("showEffects", defaultValue: false)
  /// The currently active font tag
  public static let activeTagKey = SettingKey("activeTagKey", defaultValue: LegacyTag.allTag.key)
  /// The global tuning setting that is in effect
  public static let globalTuning = SettingKey("globalTuning", defaultValue: Float(0.0))
  /// When true, global tuning is active
  public static let globalTuningEnabled = SettingKey("globalTuningEnabled", defaultValue: false)
  /// When true, the user has viewed the tutorial pages
  public static let showedTutorial = SettingKey("showedTutorial", defaultValue: false)
  /// When true, the user has viewed the changes page
  public static let showedChanges = SettingKey("showedChanges", defaultValue: "")
  /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
  public static let presetsWidthMultiplier = SettingKey("presetsWidthMultiplier", defaultValue: 1.4)
  /// The number of semitones a max pitch bend will cause in a playing note
  public static let pitchBendRange = SettingKey("pitchBendRange", defaultValue: 2)
  /// When true, the user has seen the prompt on how to restore hidden presets
  public static let showedHidePresetPrompt = SettingKey(
    "showedHidePresetPrompt", defaultValue: false)
}

/// Collection of user settings. There are two types: shared and instance. Shared settings affect both the app and the
/// AUv3 component; instance settings affect only one instance.
public struct Settings {

  /// The collection of shared settings
  public static let shared = singleton._shared
  /// The collection of per-instance settings
  public static let instance = singleton._instance

  private static let singleton = Settings()

  private let _shared: UserDefaults
  private let _instance: UserDefaults

  /**
     Initialize settings from UserDefaults.
     */
  init() {
    guard let shared = UserDefaults(suiteName: "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare")
    else {
      fatalError("unable to access SoundFontsShare")
    }

    let instance = UserDefaults.standard
    if let sharedInit = shared.persistentDomain(
      forName: "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare")
    {
      instance.register(defaults: sharedInit)
    }

    self._shared = shared
    self._instance = instance
  }
}

/// KVO properties based on the above key definitions.

extension UserDefaults {
  /// The number of days to wait after the first launch of the app before asking for a review
  @objc public dynamic var daysAfterFirstLaunchBeforeRequest: Int {
    get { self[.daysAfterFirstLaunchBeforeRequest] }
    set { self[.daysAfterFirstLaunchBeforeRequest] = newValue }
  }
  /// The number of months to wait between review requests
  @objc public dynamic var monthsAfterLastReviewBeforeRequest: Int {
    get { self[.monthsAfterLastReviewBeforeRequest] }
    set { self[.monthsAfterLastReviewBeforeRequest] = newValue }
  }
  /// The date of the first launch (not saved across reinstalls)
  @objc public dynamic var firstLaunchDate: Date {
    get { self[.firstLaunchDate] }
    set { self[.firstLaunchDate] = newValue }
  }
  /// The date of the last review request
  @objc public dynamic var lastReviewRequestDate: Date {
    get { self[.lastReviewRequestDate] }
    set { self[.lastReviewRequestDate] = newValue }
  }
  /// The version of the app for the last review request
  @objc public dynamic var lastReviewRequestVersion: String {
    get { self[.lastReviewRequestVersion] }
    set { self[.lastReviewRequestVersion] = newValue }
  }
  /// Current keyboard key labeling
  @objc public dynamic var keyLabelOption: Int {
    get { self[.keyLabelOption] }
    set { self[.keyLabelOption] = newValue }
  }
  /// Current keyboard key width
  @objc public dynamic var keyWidth: Float {
    get { self[.keyWidth] }
    set { self[.keyWidth] = newValue }
  }
  /// The lowest note on the keyboard that is currently visible
  @objc public dynamic var lowestKeyNote: Int {
    get { self[.lowestKeyNote] }
    set { self[.lowestKeyNote] = newValue }
  }
  /// When true, play a sound when changing the active preset
  @objc public dynamic var playSample: Bool {
    get { self[.playSample] }
    set { self[.playSample] = newValue }
  }
  /// When true, copy an SF2 file into the application's folder when the file is added to the app.
  @objc public dynamic var copyFilesWhenAdding: Bool {
    get { self[.copyFilesWhenAdding] }
    set { self[.copyFilesWhenAdding] = newValue }
  }
  /// When true, show a solfege label when a note is played
  @objc public dynamic var showSolfegeLabel: Bool {
    get { self[.showSolfegeLabel] }
    set { self[.showSolfegeLabel] = newValue }
  }
  /// When true, allow finger movements on the keyboard to slide the keyboard to a new position
  @objc public dynamic var slideKeyboard: Bool {
    get { self[.slideKeyboard] }
    set { self[.slideKeyboard] = newValue }
  }
  /// The current MIDI channel to use for incoming MIDI events. OMNI mode is a value of -1 (default).
  @objc public dynamic var midiChannel: Int {
    get { self[.midiChannel] }
    set { self[.midiChannel] = newValue }
  }
  /// The MIDI virtual destination ID (not usser settable)
  @objc public dynamic var midiVirtualDestinationId: Int32 {
    get { self[.midiVirtualDestinationId] }
    set { self[.midiVirtualDestinationId] = newValue }
  }
  /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
  @objc public dynamic var showEffects: Bool {
    get { self[.showEffects] }
    set { self[.showEffects] = newValue }
  }
  /// The last active preset/patch
  @objc public dynamic var lastActivePatch: Data {
    get { self[.lastActivePatch] }
    set { self[.lastActivePatch] = newValue }
  }
  /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
  @objc public dynamic var showingFavorites: Bool {
    get { self[.showingFavorites] }
    set { self[.showingFavorites] = newValue }
  }
  /// If true, the reverb AU is currently active
  @objc public dynamic var reverbEnabled: Bool {
    get { self[.reverbEnabled] }
    set { self[.reverbEnabled] = newValue }
  }
  /// If true, the reverb AU is globally active
  @objc public dynamic var reverbGlobal: Bool {
    get { self[.reverbGlobal] }
    set { self[.reverbGlobal] = newValue }
  }
  /// The current reverb preset being used
  @objc public dynamic var reverbPreset: Int {
    get { self[.reverbPreset] }
    set { self[.reverbPreset] = newValue }
  }
  /// The current reverb mix setting
  @objc public dynamic var reverbWetDryMix: Float {
    get { self[.reverbWetDryMix] }
    set { self[.reverbWetDryMix] = newValue }
  }
  /// If true, the delay AU is currently active
  @objc public dynamic var delayEnabled: Bool {
    get { self[.delayEnabled] }
    set { self[.delayEnabled] = newValue }
  }
  /// If true, the delay AU is globally active
  @objc public dynamic var delayGlobal: Bool {
    get { self[.delayGlobal] }
    set { self[.delayGlobal] = newValue }
  }
  /// The current delay amount in seconds
  @objc public dynamic var delayTime: Float {
    get { self[.delayTime] }
    set { self[.delayTime] = newValue }
  }
  /// The current feedback setting between -100% and 100%
  @objc public dynamic var delayFeedback: Float {
    get { self[.delayFeedback] }
    set { self[.delayFeedback] = newValue }
  }
  /// The current low-pass cutoff value for the delay effect
  @objc public dynamic var delayCutoff: Float {
    get { self[.delayCutoff] }
    set { self[.delayCutoff] = newValue }
  }
  /// The current delay mix setting
  @objc public dynamic var delayWetDryMix: Float {
    get { self[.delayWetDryMix] }
    set { self[.delayWetDryMix] = newValue }
  }
  /// The currently active font tag
  @objc public dynamic var activeTagKey: LegacyTag.Key {
    get { self[.activeTagKey] }
    set { self[.activeTagKey] = newValue }
  }
  /// The global tuning setting that is in effect
  @objc public dynamic var globalTuning: Float {
    get { self[.globalTuning] }
    set { self[.globalTuning] = newValue }
  }
  /// When true, global tuning is active
  @objc public dynamic var globalTuningEnabled: Bool {
    get { self[.globalTuningEnabled] }
    set { self[.globalTuningEnabled] = newValue }
  }
  /// When true, the user has viewed the tutorial pages
  @objc public dynamic var showedTutorial: Bool {
    get { self[.showedTutorial] }
    set { self[.showedTutorial] = newValue }
  }
  /// When true, the user has viewed the changes page
  @objc public dynamic var showedChanges: String {
    get { self[.showedChanges] }
    set { self[.showedChanges] = newValue }
  }
  /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
  @objc public dynamic var presetsWidthMultiplier: Double {
    get { self[.presetsWidthMultiplier] }
    set { self[.presetsWidthMultiplier] = newValue }
  }
  /// The number of semitones a max pitch bend will cause in a playing note
  @objc public dynamic var pitchBendRange: Int {
    get { self[.pitchBendRange] }
    set { self[.pitchBendRange] = newValue }
  }
  /// When true, the user has seen the prompt on how to restore hidden presets
  @objc public dynamic var showedHidePresetPrompt: Bool {
    get { self[.showedHidePresetPrompt] }
    set { self[.showedHidePresetPrompt] = newValue }
  }
}
