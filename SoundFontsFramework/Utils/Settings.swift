// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/// Key definitions that include the key name, the value type, and any default value associated with the setting if not
/// found
public extension SettingKeys {

    // AskForReview settings

    /// The number of days to wait after the first launch of the app before asking for a review
    static let daysAfterFirstLaunchBeforeRequest = SettingKey("daysAfterFirstLaunchBeforeRequest", defaultValue: 14)
    /// The number of months to wait between review requests
    static let monthsAfterLastReviewBeforeRequest = SettingKey("monthsAfterLastReviewBeforeRequest", defaultValue: 2)
    /// The date of the first launch (not saved across reinstalls)
    static let firstLaunchDate = SettingKey("firstLaunchDate", defaultValue: Date.distantPast)
    /// The date of the last review request
    static let lastReviewRequestDate = SettingKey("lastReviewRequestDate", defaultValue: Date.distantPast)
    /// The version of the app for the last review request
    static let lastReviewRequestVersion = SettingKey("lastReviewRequestVersion", defaultValue: "")

    // App settings

    /// Current keyboard key labeling
    static let keyLabelOption = SettingKey("keyLabelOption", defaultValue: KeyLabelOption.cOnly.rawValue)
    /// Current keyboard key width
    static let keyWidth = SettingKey<Float>("keyWidth", defaultValue: 64.0)
    /// The last active preset/patch
    static let lastActivePatch = SettingKey("lastActivePatch", defaultValue: Data())
    /// The lowest note on the keyboard that is currently visible
    static let lowestKeyNote = SettingKey("lowestKeyNote", defaultValue: 48)
    /// When true, play a sound when changing the active preset
    static let playSample = SettingKey("playSample", defaultValue: false)
    /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
    static let showingFavorites = SettingKey("showingFavorites", defaultValue: false)
    /// When true, show a solfege label when a note is played
    static let showSolfegeLabel = SettingKey("showSolfegeLabel", defaultValue: true)
    /// When true, copy an SF2 file into the application's folder when the file is added to the app.
    static let copyFilesWhenAdding = SettingKey("copyFilesWhenAdding", defaultValue: true)
    /// When true, allow finger movements on the keyboard to slide the keyboard to a new position
    static let slideKeyboard = SettingKey("slideKeyboard", defaultValue: false)

    /// The current MIDI channel to use for incoming MIDI events. OMNI mode is a value of -1 (default).
    static let midiChannel = SettingKey("midiChannel", defaultValue: -1)
    /// The MIDI virtual destination ID (not usser settable)
    static let midiVirtualDestinationId = SettingKey("midiVirtualDestinationId", defaultValue: Int32(0))

    /// If true, the reverb AU is currently active
    static let reverbEnabled = SettingKey("reverbEnabled", defaultValue: false)
    /// If true, the reverb AU is globally active
    static let reverbGlobal = SettingKey("reverbGlobal", defaultValue: false)
    /// The current reverb preset being used
    static let reverbPreset = SettingKey("reverbPreset", defaultValue: 1)
    /// The current reverb mix setting
    static let reverbWetDryMix = SettingKey("reverbWetDryMix", defaultValue: Float(35.0))

    /// If true, the delay AU is currently active
    static let delayEnabled = SettingKey("delayEnabled", defaultValue: false)
    /// If true, the delay AU is globally active
    static let delayGlobal = SettingKey("delayGlobal", defaultValue: false)
    /// The current delay amount in seconds
    static let delayTime = SettingKey("delayTime", defaultValue: Float(0.19))
    /// The current feedback setting between -100% and 100%
    static let delayFeedback = SettingKey("delayFeedback", defaultValue: Float(-75.0))
    /// The current low-pass cutoff value for the delay effect
    static let delayCutoff = SettingKey("delayCutoff", defaultValue: Float(15000.0))
    /// The current delay mix setting
    static let delayWetDryMix = SettingKey("delayWetDryMix", defaultValue: Float(45.0))

    /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
    static let showEffects = SettingKey("showEffects", defaultValue: false)
    /// The currently active font tag
    static let activeTagIndex = SettingKey("activeTagIndex", defaultValue: 0)
    /// The global tuning setting that is in effect
    static let globalTuning = SettingKey("globalTuning", defaultValue: Float(0.0))
    /// When true, global tuning is active
    static let globalTuningEnabled = SettingKey("globalTuningEnabled", defaultValue: false)
    /// When true, the user has viewed the tutorial pages
    static let showedTutorial = SettingKey("showedTutorial", defaultValue: false)
    /// When true, the user has viewed the changes page
    static let showedChanges = SettingKey("showedChanges", defaultValue: "")
    /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
    static let presetsWidthMultiplier = SettingKey("presetsWidthMultiplier", defaultValue: 1.4)
    /// The number of semitones a max pitch bend will cause in a playing note
    static let pitchBendRange = SettingKey("pitchBendRange", defaultValue: 2)
}

/**
 Collection of user settings. There are two types: shared and instance. Shared settings affect both the app and the
 AUv3 component; instance settings affect only one instance.
 */
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
        guard let shared = UserDefaults(suiteName: "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare") else {
            fatalError("unable to access SoundFontsShare")
        }

        let instance = UserDefaults.standard
        if let sharedInit = shared.persistentDomain(forName: "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare") {
            instance.register(defaults: sharedInit)
        }

        self._shared = shared
        self._instance = instance
    }
}

/// KVO properties based on the above key definitions.

public extension UserDefaults {
    /// The number of days to wait after the first launch of the app before asking for a review
    @objc dynamic var daysAfterFirstLaunchBeforeRequest: Int {
        get { self[.daysAfterFirstLaunchBeforeRequest] }
        set { self[.daysAfterFirstLaunchBeforeRequest] = newValue }
    }
    /// The number of months to wait between review requests
    @objc dynamic var monthsAfterLastReviewBeforeRequest: Int {
        get { self[.monthsAfterLastReviewBeforeRequest] }
        set { self[.monthsAfterLastReviewBeforeRequest] = newValue }
    }
    /// The date of the first launch (not saved across reinstalls)
    @objc dynamic var firstLaunchDate: Date {
        get { self[.firstLaunchDate] }
        set { self[.firstLaunchDate] = newValue }
    }
    /// The date of the last review request
    @objc dynamic var lastReviewRequestDate: Date {
        get { self[.lastReviewRequestDate] }
        set { self[.lastReviewRequestDate] = newValue }
    }
    /// The version of the app for the last review request
    @objc dynamic var lastReviewRequestVersion: String {
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
    @objc dynamic var lowestKeyNote: Int {
        get { self[.lowestKeyNote] }
        set { self[.lowestKeyNote] = newValue}
    }
    /// When true, play a sound when changing the active preset
    @objc dynamic var playSample: Bool {
        get { self[.playSample] }
        set { self[.playSample] = newValue }
    }
    /// When true, copy an SF2 file into the application's folder when the file is added to the app.
    @objc dynamic var copyFilesWhenAdding: Bool {
        get { self[.copyFilesWhenAdding] }
        set { self[.copyFilesWhenAdding] = newValue }
    }
    /// When true, show a solfege label when a note is played
    @objc dynamic var showSolfegeLabel: Bool {
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
    /// The MIDI virtual destination ID (not usser settable)
    @objc dynamic var midiVirtualDestinationId: Int32 {
        get { self[.midiVirtualDestinationId] }
        set { self[.midiVirtualDestinationId] = newValue }
    }
    /// When true, the effects panel is visible. Used to restore UI state when relaunching the app.
    @objc dynamic var showEffects: Bool {
        get { self[.showEffects] }
        set { self[.showEffects] = newValue }
    }
    /// The last active preset/patch
    @objc dynamic var lastActivePatch: Data {
        get { self[.lastActivePatch] }
        set { self[.lastActivePatch] = newValue }
    }
    /// When true, the upper view is showing the favorites. Used to restore the app to the last view.
    @objc dynamic var showingFavorites: Bool {
        get { self[.showingFavorites] }
        set { self[.showingFavorites] = newValue }
    }
    /// If true, the reverb AU is currently active
    @objc dynamic var reverbEnabled: Bool {
        get { self[.reverbEnabled] }
        set { self[.reverbEnabled] = newValue }
    }
    /// If true, the reverb AU is globally active
    @objc dynamic var reverbGlobal: Bool {
        get { self[.reverbGlobal] }
        set { self[.reverbGlobal] = newValue }
    }
    /// The current reverb preset being used
    @objc dynamic var reverbPreset: Int {
        get { self[.reverbPreset] }
        set { self[.reverbPreset] = newValue }
    }
    /// The current reverb mix setting
    @objc dynamic var reverbWetDryMix: Float {
        get { self[.reverbWetDryMix] }
        set { self[.reverbWetDryMix] = newValue }
    }
    /// If true, the delay AU is currently active
    @objc dynamic var delayEnabled: Bool {
        get { self[.delayEnabled] }
        set { self[.delayEnabled] = newValue }
    }
    /// If true, the delay AU is globally active
    @objc dynamic var delayGlobal: Bool {
        get { self[.delayGlobal] }
        set { self[.delayGlobal] = newValue }
    }
    /// The current delay amount in seconds
    @objc dynamic var delayTime: Float {
        get { self[.delayTime] }
        set { self[.delayTime] = newValue }
    }
    /// The current feedback setting between -100% and 100%
    @objc dynamic var delayFeedback: Float {
        get { self[.delayFeedback] }
        set { self[.delayFeedback] = newValue }
    }
    /// The current low-pass cutoff value for the delay effect
    @objc dynamic var delayCutoff: Float {
        get { self[.delayCutoff] }
        set { self[.delayCutoff] = newValue }
    }
    /// The current delay mix setting
    @objc dynamic var delayWetDryMix: Float {
        get { self[.delayWetDryMix] }
        set { self[.delayWetDryMix] = newValue }
    }
    /// The currently active font tag
    @objc dynamic var activeTagIndex: Int {
        get { self[.activeTagIndex] }
        set { self[.activeTagIndex] = newValue }
    }
    /// The global tuning setting that is in effect
    @objc dynamic var globalTuning: Float {
        get { self[.globalTuning] }
        set { self[.globalTuning] = newValue }
    }
    /// When true, global tuning is active
    @objc dynamic var globalTuningEnabled: Bool {
        get { self[.globalTuningEnabled] }
        set { self[.globalTuningEnabled] = newValue }
    }
    /// When true, the user has viewed the tutorial pages
    @objc dynamic var showedTutorial: Bool {
        get { self[.showedTutorial] }
        set { self[.showedTutorial] = newValue }
    }
    /// When true, the user has viewed the changes page
    @objc dynamic var showedChanges: String {
        get { self[.showedChanges] }
        set { self[.showedChanges] = newValue }
    }
    /// The current scale factor that controls how much of the presets view to show in comparison to the fonts view
    @objc dynamic var presetsWidthMultiplier: Double {
        get { self[.presetsWidthMultiplier] }
        set { self[.presetsWidthMultiplier] = newValue }
    }
    /// The number of semitones a max pitch bend will cause in a playing note
    @objc dynamic var pitchBendRange: Int {
        get { self[.pitchBendRange] }
        set { self[.pitchBendRange] = newValue }
    }
}
