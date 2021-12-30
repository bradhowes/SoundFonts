// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation
import os.log

/// Collection of user settings.
public final class Settings: NSObject {
  private static let log = Logging.logger("Settings")

  public static let defaultSuiteName = "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare"
  public let keyPrefix: String
  public let identity: FileManager.Identity?
  public let storage: UserDefaults
  public var registered = Set<String>()

  /**
   Initialize settings from UserDefaults.
   */
  public init(inApp: Bool, suiteName: String = Settings.defaultSuiteName) {
    os_log(.info, log: Self.log, "init - BEGIN: %d %{public}s", inApp, suiteName)
    os_log(.info, log: Self.log, "application directory: %{public}s", NSHomeDirectory())

    guard
      let defaults = UserDefaults(suiteName: suiteName)
    else {
      os_log(.error, log: Self.log, "failed to access %{public}s", suiteName)
      fatalError("unable to access \(suiteName)")
    }

    self.storage = defaults

    if inApp {
      self.identity = nil
      self.keyPrefix = ""
    }
    else {
      let identity = FileManager.default.openIdentity()
      os_log(.info, log: Self.log, "using identity %d", identity.index)
      self.identity = identity
      self.keyPrefix = "\(identity.index)_"
    }

    os_log(.info, log: Self.log, "init - END")
  }

  func get<T>(key: String, defaultValue: T) -> T {
    if let value = storage.object(forKey: key) as? T { return value }
    storage.register(defaults: [key: defaultValue])
    return defaultValue
  }

  func set<T>(key: String, value: T) { storage.set(value, forKey: key) }
  func remove<T>(key: SettingKey<T>) { storage.removeObject(forKey: key.key) }
}

public extension SettingKeys {
  // AskForReview settings

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

  // App settings

  /// Current keyboard key labeling
  static let keyLabelOption = SettingKey("keyLabelOption", KeyLabelOption.cOnly.rawValue)
  /// Current keyboard key width
  static let keyWidth = SettingKey<Float>("keyWidth", 64.0)
  /// The last active preset (name is legacy)
  static let lastActivePreset = SettingKey("lastActivePatch", ActivePresetKind.none)
  /// The lowest note on the keyboard that is currently visible
  static let lowestKeyNote = SettingKey("lowestKeyNote", 48)
  /// When true, play a sound when changing the active preset
  static let playSample = SettingKey("playSample", false)
  /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
  static let showingFavorites = SettingKey("showingFavorites", false)
  /// When true, show a solfege label when a note is played
  static let showSolfegeLabel = SettingKey("showSolfegeLabel", true)
  /// When true, copy an SF2 file into the application's folder when the file is added to the app.
  static let copyFilesWhenAdding = SettingKey("copyFilesWhenAdding", true)
  /// When true, allow finger movements on the keyboard to slide the keyboard to a new position
  static let slideKeyboard = SettingKey("slideKeyboard", false)

  /// The current MIDI channel to use for incoming MIDI events. OMNI mode is a value of -1 (default).
  static let midiChannel = SettingKey("midiChannel", -1)
  /// The MIDI virtual input ID (not user settable)
  static let virtualMidiInId = SettingKey("virtualMidiInId", 0)
  /// The MIDI virtual output ID (not user settable)
  static let virtualMidiOutId = SettingKey("virtualMidiOutId", 0)

  /// If true, the reverb AU is currently active
  static let reverbEnabled = SettingKey("reverbEnabled", false)
  /// If true, the reverb AU is globally active
  static let reverbGlobal = SettingKey("reverbGlobal", false)
  /// The current reverb preset being used
  static let reverbPreset = SettingKey("reverbPreset", 1)
  /// The current reverb mix setting
  static let reverbWetDryMix = SettingKey("reverbWetDryMix", Float(35.0))

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

  /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
  static let showEffects = SettingKey("showEffects", false)
  /// The currently active font tag
  static let activeTagKey = SettingKey("activeTagKey", Tag.allTag.key)
  /// The global tuning setting that is in effect
  static let globalTuning = SettingKey("globalTuning", Float(0.0))
  /// When true, global tuning is active
  static let globalTuningEnabled = SettingKey("globalTuningEnabled", false)
  /// When true, the user has viewed the tutorial pages
  static let showedTutorial = SettingKey("showedTutorial", false)
  /// When true, the user has viewed the changes page
  static let showedChanges = SettingKey("showedChanges", "")
  /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
  static let presetsWidthMultiplier = SettingKey("presetsWidthMultiplier", 1.4)
  /// The number of semitones a max pitch bend will cause in a playing note
  static let pitchBendRange = SettingKey("pitchBendRange", 2)
  /// When true, the user has seen the prompt on how to restore hidden presets
  static let showedHidePresetPrompt = SettingKey("showedHidePresetPrompt", false)
}

/// KVO properties based on the above key definitions.

extension Settings {

  /**
   Enable subscripting by SettingKey instances.

   - parameter key: SettingKey instance to use as a key into UserDefaults
   - returns: instance of the template type from UserDefaults
   */
  @inlinable
  subscript<T>(key: SettingKey<T>) -> T {
    get { key.get(self) }
    set { key.set(self, newValue) }
  }

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
  /// The MIDI virtual input ID (not user settable)
  @objc public dynamic var virtualMidiInId: Int {
    get { self[.virtualMidiInId] }
    set { self[.virtualMidiInId] = newValue }
  }
  /// The MIDI virtual output ID (not user settable)
  @objc public dynamic var virtualMidiOutId: Int {
    get { self[.virtualMidiOutId] }
    set { self[.virtualMidiOutId] = newValue }
  }
  /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
  @objc public dynamic var showEffects: Bool {
    get { self[.showEffects] }
    set { self[.showEffects] = newValue }
  }
  /// The last active preset
  public dynamic var lastActivePreset: ActivePresetKind {
    get { self[.lastActivePreset] }
    set { self[.lastActivePreset] = newValue }
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
  /// If true, the chorus AU is currently active
  @objc public dynamic var chorusEnabled: Bool {
    get { self[.chorusEnabled] }
    set { self[.chorusEnabled] = newValue }
  }
  /// If true, the chorus AU is globally active
  @objc public dynamic var chorusGlobal: Bool {
    get { self[.chorusGlobal] }
    set { self[.chorusGlobal] = newValue }
  }
  /// The current chorus rate in seconds
  @objc public dynamic var chorusRate: Float {
    get { self[.chorusRate] }
    set { self[.chorusRate] = newValue }
  }
  /// The current chorus delay
  @objc public dynamic var chorusDelay: Float {
    get { self[.chorusDelay] }
    set { self[.chorusDelay] = newValue }
  }
  /// The current chorus depth
  @objc public dynamic var chorusDepth: Float {
    get { self[.chorusDepth] }
    set { self[.chorusDepth] = newValue }
  }
  /// The current feedback setting between -100% and 100%
  @objc public dynamic var chorusFeedback: Float {
    get { self[.chorusFeedback] }
    set { self[.chorusFeedback] = newValue }
  }
  /// The current chorus mix setting
  @objc public dynamic var chorusWetDryMix: Float {
    get { self[.chorusWetDryMix] }
    set { self[.chorusWetDryMix] = newValue }
  }
  /// The current chorus neg feedback switch
  @objc public dynamic var chorusNegFeedback: Bool {
    get { self[.chorusNegFeedback] }
    set { self[.chorusNegFeedback] = newValue }
  }
  /// The current chorus odd 90° switch
  @objc public dynamic var chorusOdd90: Bool {
    get { self[.chorusOdd90] }
    set { self[.chorusOdd90] = newValue }
  }
  /// The currently active font tag
  @objc public dynamic var activeTagKey: Tag.Key {
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
