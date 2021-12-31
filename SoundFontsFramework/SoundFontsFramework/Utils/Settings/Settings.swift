// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import os.log

/**
 Collection of user settings. All UserDefaults access should be done through the instance in order to properly
 handle when running as an AUv3 app extension, and not as the app.
*/
public final class Settings: NSObject {
  private static let log = Logging.logger("Settings")

  public static let defaultSuiteName = "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare"
  @usableFromInline
  internal let storage: UserDefaults
  private let sessionIdentity: FileManager.Identity?

  public var identity: Int? { sessionIdentity?.index }
  public let keyPrefix: String

  /**
   Construct new Settings instance.

   - parameter inApp: `true` if running as the app
   - parameter suiteName: the UserDefaults suite to load (only for testing)
   - parameter identity: optional identity to take on (only for testing)
   */
  public init(inApp: Bool, suiteName: String = Settings.defaultSuiteName, identity: Int? = nil) {
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
      self.sessionIdentity = nil
      self.keyPrefix = ""
    }
    else {
      let sessionIdentity: FileManager.Identity = {
        if identity != nil {
          return .init(identity!, URL(fileURLWithPath: NSHomeDirectory()), -1)
        }
        return FileManager.default.openIdentity()
      }()

      os_log(.info, log: Self.log, "using identity %d", sessionIdentity.index)
      self.sessionIdentity = sessionIdentity
      self.keyPrefix = "\(sessionIdentity.index)_"
    }

    super.init()

    os_log(.info, log: Self.log, "init - END")
  }
}

extension Settings {

  /**
   Obtain a settings key that is appropriate for the instance that is running (app or AUv3 component)

   - parameter key: the primary key
   - returns: the instance key to use
   */
  @inlinable
  public func instanceKey(_ key: String, isGlobal: Bool) -> String { isGlobal ? key : self.keyPrefix + key }

  /**
   Fetch a settings value with a specific type.

   - parameter key: the name of the setting to fetch
   - parameter defaultValue: the default value to return if the setting has not been set
   - parameter isGlobal: `true` if the setting is a global/shared setting and not distinct for each running instance.
   - returns: the setting value
   */
  @inlinable
  public func get<T>(key: String, defaultValue: T, isGlobal: Bool) -> T {
    let key = instanceKey(key, isGlobal: isGlobal)
    if let value = storage.object(forKey: key) as? T { return value }
    storage.register(defaults: [key: defaultValue])
    return defaultValue
  }

  /**
   Store a settings value with a specific type.

   - parameter key: the name of the setting to set
   - parameter value: the value to assign to the setting
   - parameter isGlobal: `true` if the setting is a global/shared setting and not distinct for each running instance.
   */
  @inlinable
  public func set<T>(key: String, value: T, isGlobal: Bool) {
    storage.set(value, forKey: instanceKey(key, isGlobal: isGlobal))
  }

  /**
   Remove a setting.

   - parameter key: the name of the setting to remove
   - parameter isGlobal: `true` if the setting is a global/shared setting and not distinct for each running instance.
   */
  @inlinable
  public func remove<T>(key: SettingKey<T>, isGlobal: Bool) {
    storage.removeObject(forKey: instanceKey(key.key, isGlobal: isGlobal))
  }

  /**
   Obtain a type-erased value from the setting database.

   - parameter key: the name of the setting to set
   - parameter isGlobal: `true` if the setting is a global/shared setting and not distinct for each running instance.
   - returns: the optional value found in the database
   */
  @inlinable
  public func raw(key: String, isGlobal: Bool) -> Any? {
    storage.object(forKey: instanceKey(key, isGlobal: isGlobal))
  }

  /**
   Enable subscripting by SettingKey instance and forwards operations to type-specific methods.

   - parameter key: SettingKey instance to use as a key
   - returns: setting value with the given type
   */
  @inlinable
  public subscript<T>(key: SettingKey<T>) -> T {
    get { T.get(key: key.key, defaultValue: key.defaultValue, source: self, isGlobal: key.isGlobal) }
    set { T.set(key: key.key, value: newValue, source: self, isGlobal: key.isGlobal) }
  }

  /**
   Set/update a setting using a value taken from a type-erased dictionary. If the given dictionary has an entry that
   matches the given key and the value in the dictionary can be used to create value of type `T`, then the settings
   database will be updated with the typed value.

   - parameter key: SettingKey instance to use as a key
   - parameter from: the dictionary holding values to use
   */
  @inlinable
  public func restore<T>(key: SettingKey<T>, from: [String: Any]) {
    if let newValue = from[key.key] as? T {
      T.set(key: key.key, value: newValue, source: self, isGlobal: key.isGlobal)
    }
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
  /// The MIDI virtual input ID (not user settable)
  var virtualMidiInId: Int {
    get { self[.virtualMidiInId] }
    set { self[.virtualMidiInId] = newValue }
  }
  /// The MIDI virtual output ID (not user settable)
  var virtualMidiOutId: Int {
    get { self[.virtualMidiOutId] }
    set { self[.virtualMidiOutId] = newValue }
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
  /// If true, the chorus AU is currently active
  var chorusEnabled: Bool {
    get { self[.chorusEnabled] }
    set { self[.chorusEnabled] = newValue }
  }
  /// If true, the chorus AU is globally active
  var chorusGlobal: Bool {
    get { self[.chorusGlobal] }
    set { self[.chorusGlobal] = newValue }
  }
  /// The current chorus rate in seconds
  var chorusRate: Float {
    get { self[.chorusRate] }
    set { self[.chorusRate] = newValue }
  }
  /// The current chorus delay
  var chorusDelay: Float {
    get { self[.chorusDelay] }
    set { self[.chorusDelay] = newValue }
  }
  /// The current chorus depth
  var chorusDepth: Float {
    get { self[.chorusDepth] }
    set { self[.chorusDepth] = newValue }
  }
  /// The current feedback setting between -100% and 100%
  var chorusFeedback: Float {
    get { self[.chorusFeedback] }
    set { self[.chorusFeedback] = newValue }
  }
  /// The current chorus mix setting
  var chorusWetDryMix: Float {
    get { self[.chorusWetDryMix] }
    set { self[.chorusWetDryMix] = newValue }
  }
  /// The current chorus neg feedback switch
  var chorusNegFeedback: Bool {
    get { self[.chorusNegFeedback] }
    set { self[.chorusNegFeedback] = newValue }
  }
  /// The current chorus odd 90° switch
  var chorusOdd90: Bool {
    get { self[.chorusOdd90] }
    set { self[.chorusOdd90] = newValue }
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
}
