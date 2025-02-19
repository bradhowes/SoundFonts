// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os.log

/**
 Collection of user settings. All UserDefaults access should be done through the instance in order to properly
 handle when running as an AUv3 app extension, and not as the app.
*/
public final class Settings: NSObject {
  private static let log: Logger = Logging.logger("Settings")

  @usableFromInline
  internal var log: Logger { Self.log }

  @usableFromInline
  internal let storage: UserDefaults

  @usableFromInline
  internal var componentSettings: [String: Any]?

  /**
   Construct new Settings instance.

   - parameter suiteName: the UserDefaults suite to load (only for testing)
   */
  public init(suiteName: String = "") {
    Self.log.debug("init BEGIN - suiteName: '\(suiteName, privacy: .public)'")
    if suiteName == "" {
      self.storage = UserDefaults.standard
    } else {
      guard let defaults = UserDefaults(suiteName: suiteName) else {
        Self.log.error("failed to access suite '\(suiteName, privacy: .public)'")
        fatalError("unable to access \(suiteName)")
      }
      self.storage = defaults
    }

    super.init()

    log.debug("application directory: \(NSHomeDirectory(), privacy: .public)")
    log.debug("init END")
  }
}

extension Settings {

  /**
   Install values to serve as the settings for a AUv3 component. These would normally come from the `fullState` value.

   - parameter state: dictionary of settings to use for setting values
   */
  @inlinable
  public func setAudioUnitState(_ state: [String: Any]) {
    log.debug("setAudioUnitState BEGIN - \(state.description, privacy: .public)")
    componentSettings = state
    log.debug("setAudioUnitState END")
  }
}

extension Settings {

  /**
   Fetch a settings value with a specific type.

   - parameter key: the name of the setting to fetch
   - parameter defaultValue: the default value to return if the setting has not been set
   - returns: the setting value
   */
  @inlinable
  public func get<T>(key: String, defaultValue: T) -> T {
    if let value = componentSettings?[key] as? T {
      return value
    }
    if let value = storage.object(forKey: key) as? T {
      return value
    }
    storage.register(defaults: [key: defaultValue])
    return defaultValue
  }

  /**
   Store a settings value with a specific type.

   - parameter key: the name of the setting to set
   - parameter value: the value to assign to the setting
   */
  @inlinable
  public func set<T>(key: String, value: T) {
    if componentSettings != nil {
      componentSettings?[key] = value
    } else {
      storage.set(value, forKey: key)
    }
  }

  /**
   Remove a setting.

   - parameter key: the name of the setting to remove
   */
  @inlinable
  public func remove<T>(key: SettingKey<T>) {
    if var state = componentSettings {
      state.removeValue(forKey: key.key)
    }
    storage.removeObject(forKey: key.key)
  }

  /**
   Obtain a type-erased value from the setting database.

   - parameter key: the name of the setting to set
   - returns: the optional value found in the database
   */
  @inlinable
  public func raw(key: String) -> Any? {
    if let state = componentSettings, let value = state[key] { return value }
    return storage.object(forKey: key)
  }

  /**
   Enable subscripting by SettingKey instance and forwards operations to type-specific methods.

   - parameter key: SettingKey instance to use as a key
   - returns: setting value with the given type
   */
  @inlinable
  public subscript<T>(key: SettingKey<T>) -> T {
    get { T.get(key: key.key, defaultValue: key.defaultValue, source: self) }
    set { T.set(key: key.key, value: newValue, source: self) }
  }
}

public extension Settings {

  /// The number of days to wait after the first launch of the app before asking for a review
  var daysAfterFirstLaunchBeforeRequest: Int {
    get { self[.daysAfterFirstLaunchBeforeRequest] }
    set { self[.daysAfterFirstLaunchBeforeRequest] = newValue }
  }
  /// The number of months to wait between review requests
  var monthsAfterLastReviewBeforeRequest: Int {
    get { self[.monthsAfterLastReviewBeforeRequest] }
    set { self[.monthsAfterLastReviewBeforeRequest] = newValue }
  }
  /// The date of the first launch (not saved across reinstalls)
  var firstLaunchDate: Date {
    get { self[.firstLaunchDate] }
    set { self[.firstLaunchDate] = newValue }
  }
  /// The date of the last review request
  var lastReviewRequestDate: Date {
    get { self[.lastReviewRequestDate] }
    set { self[.lastReviewRequestDate] = newValue }
  }
  /// The version of the app for the last review request
  var lastReviewRequestVersion: String {
    get { self[.lastReviewRequestVersion] }
    set { self[.lastReviewRequestVersion] = newValue }
  }
  /// Current keyboard key labeling
  @objc dynamic var keyLabelOption: Int {
    get { self[.keyLabelOption] }
    set { self[.keyLabelOption] = newValue }
  }
  /// Current keyboard key width
  @objc dynamic var keyWidth: Float {
    get { self[.keyWidth] }
    set { self[.keyWidth] = newValue }
  }
  /// The lowest note on the keyboard that is currently visible
  var lowestKeyNote: Int {
    get { self[.lowestKeyNote] }
    set { self[.lowestKeyNote] = newValue }
  }
  /// When true, play a sound when changing the active preset
  var playSample: Bool {
    get { self[.playSample] }
    set { self[.playSample] = newValue }
  }
  /// When true, copy an SF2 file into the application's folder when the file is added to the app.
  var copyFilesWhenAdding: Bool {
    get { self[.copyFilesWhenAdding] }
    set { self[.copyFilesWhenAdding] = newValue }
  }
  /// When true, show a solfege label when a note is played
  var showSolfegeLabel: Bool {
    get { self[.showSolfegeLabel] }
    set { self[.showSolfegeLabel] = newValue }
  }
  /// When true, allow finger movements on the keyboard to slide the keyboard to a new position
  @objc dynamic var slideKeyboard: Bool {
    get { self[.slideKeyboard] }
    set { self[.slideKeyboard] = newValue }
  }
  /// The current MIDI channel to use for incoming MIDI events. OMNI mode is a value of -1 (default).
  @objc dynamic var midiChannel: Int {
    get { self[.midiChannel] }
    set { self[.midiChannel] = newValue }
  }
  /// The unique ID of the input port (not user settable)
  var midiInputPortUniqueId: Int {
    get { self[.midiInputPortUniqueId] }
    set { self[.midiInputPortUniqueId] = newValue }
  }
  /// The MIDI virtual output ID (not user settable)
  var midiOutputPortUniqueId: Int {
    get { self[.midiOutputPortUniqueId] }
    set { self[.midiOutputPortUniqueId] = newValue }
  }
  /// If true, processing MIDI messages when app is in the background
  var backgroundMIDIProcessingEnabled: Bool {
    get { self[.backgroundMIDIProcessingEnabled] }
    set { self[.backgroundMIDIProcessingEnabled] = newValue }
  }
  /// If true, auto-connect to new MIDI devices
  var autoConnectNewMIDIDeviceEnabled: Bool {
    get { self[.autoConnectNewMIDIDeviceEnabled] }
    set { self[.autoConnectNewMIDIDeviceEnabled] = newValue }
  }

  /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
  var showEffects: Bool {
    get { self[.showEffects] }
    set { self[.showEffects] = newValue }
  }
  /// The last active preset
  var lastActivePreset: ActivePresetKind {
    get { self[.lastActivePreset] }
    set { self[.lastActivePreset] = newValue }
  }
  /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
  var showingFavorites: Bool {
    get { self[.showingFavorites] }
    set { self[.showingFavorites] = newValue }
  }
  /// If true, the reverb AU is currently active
  var reverbEnabled: Bool {
    get { self[.reverbEnabled] }
    set { self[.reverbEnabled] = newValue }
  }
  /// If true, the reverb AU is globally active
  var reverbGlobal: Bool {
    get { self[.reverbGlobal] }
    set { self[.reverbGlobal] = newValue }
  }
  /// The current reverb preset being used
  var reverbPreset: Int {
    get { self[.reverbPreset] }
    set { self[.reverbPreset] = newValue }
  }
  /// The current reverb mix setting
  var reverbWetDryMix: Float {
    get { self[.reverbWetDryMix] }
    set { self[.reverbWetDryMix] = newValue }
  }
  /// If true, the delay AU is currently active
  var delayEnabled: Bool {
    get { self[.delayEnabled] }
    set { self[.delayEnabled] = newValue }
  }
  /// If true, the delay AU is globally active
  var delayGlobal: Bool {
    get { self[.delayGlobal] }
    set { self[.delayGlobal] = newValue }
  }
  /// The current delay amount in seconds
  var delayTime: Float {
    get { self[.delayTime] }
    set { self[.delayTime] = newValue }
  }
  /// The current feedback setting between -100% and 100%
  var delayFeedback: Float {
    get { self[.delayFeedback] }
    set { self[.delayFeedback] = newValue }
  }
  /// The current low-pass cutoff value for the delay effect
  var delayCutoff: Float {
    get { self[.delayCutoff] }
    set { self[.delayCutoff] = newValue }
  }
  /// The current delay mix setting
  var delayWetDryMix: Float {
    get { self[.delayWetDryMix] }
    set { self[.delayWetDryMix] = newValue }
  }
  /// The currently active font tag
  @objc dynamic var activeTagKey: Tag.Key {
    get { self[.activeTagKey] }
    set { self[.activeTagKey] = newValue }
  }
  /// The global tuning setting that is in effect
  var globalTuning: Float {
    get { self[.globalTuning] }
    set { self[.globalTuning] = newValue }
  }
  /// The global transpose that is in effect (-1100 - +1100)
  var globalTranspose: Int {
    get { self[.globalTranspose] }
    set { self[.globalTranspose] = newValue }
  }
  /// When true, global tuning is active
  var globalTuningEnabled: Bool {
    get { self[.globalTuningEnabled] }
    set { self[.globalTuningEnabled] = newValue }
  }
  /// When true, the user has viewed the tutorial pages
  var showedTutorial: Bool {
    get { self[.showedTutorial] }
    set { self[.showedTutorial] = newValue }
  }
  /// When true, the user has viewed the changes page
  var showedChanges: String {
    get { self[.showedChanges] }
    set { self[.showedChanges] = newValue }
  }
  var notifiedAboutBuiltinFonts: Bool {
    get { self[.notifiedAboutBuiltinFonts] }
    set { self[.notifiedAboutBuiltinFonts] = newValue }
  }
  /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
  var presetsWidthMultiplier: Double {
    get { self[.presetsWidthMultiplier] }
    set { self[.presetsWidthMultiplier] = newValue }
  }
  /// The number of semitones a max pitch bend will cause in a playing note
  var pitchBendRange: Int {
    get { self[.pitchBendRange] }
    set { self[.pitchBendRange] = newValue }
  }
  /// When true, the user has seen the prompt on how to restore hidden presets
  var showedHidePresetPrompt: Bool {
    get { self[.showedHidePresetPrompt] }
    set { self[.showedHidePresetPrompt] = newValue }
  }
  var useSF2Engine: Bool {
    get { self[.useSF2Engine] }
    set { self[.useSF2Engine] = newValue }
  }
}
