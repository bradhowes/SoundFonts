// Copyright © 2020 Brad Howes. All rights reserved.

import Foundation

/// Global variable to keep things concise.
public let settings = UserDefaults(suiteName: "9GE3SKDXJM.group.com.braysoftware.SoundFontsShare") ?? UserDefaults.standard

/// Key definitions that include the key name, the value type, and any default value associated with the setting if not found
public extension SettingKeys {

    // AskForReview settings
    static let daysAfterFirstLaunchBeforeRequest = SettingKey("daysAfterFirstLaunchBeforeRequest", defaultValue: 14)
    static let monthsAfterLastReviewBeforeRequest = SettingKey("monthsAfterLastReviewBeforeRequest", defaultValue: 2)
    static let firstLaunchDate = SettingKey("firstLaunchDate", defaultValue: Date.distantPast)
    static let lastReviewRequestDate = SettingKey("lastReviewRequestDate", defaultValue: Date.distantPast)
    static let lastReviewRequestVersion = SettingKey("lastReviewRequestVersion", defaultValue: "")

    // App settings
    static let keyLabelOption = SettingKey("keyLabelOption", defaultValue: KeyLabelOption.cOnly.rawValue)
    static let keyWidth = SettingKey<Float>("keyWidth", defaultValue: 64.0)
    static let lastActivePatch = SettingKey("lastActivePatch", defaultValue: Data())
    static let lowestKeyNote = SettingKey("lowestKeyNote", defaultValue: 48)
    static let playSample = SettingKey("playSample", defaultValue: false)
    static let showingFavorites = SettingKey("showingFavorites", defaultValue: false)
    static let showSolfegeLabel = SettingKey("showSolfegeLabel", defaultValue: true)
    static let copyFilesWhenAdding = SettingKey("copyFilesWhenAdding", defaultValue: true)
    static let slideKeyboard = SettingKey("slideKeyboard", defaultValue: false)
    static let midiChannel = SettingKey("midiChannel", defaultValue: -1) // omni channel by default
    static let reverbPreset = SettingKey("reverbPreset", defaultValue: -1) // no reverb
    static let reverbMix = SettingKey("reverbMix", defaultValue: Float(20.0))
    static let showEffects = SettingKey("showEffects", defaultValue: false)
}

/// KVO properties based on the above key definitions.
public extension UserDefaults {
    @objc dynamic var daysAfterFirstLaunchBeforeRequest: Int {
        get { self[.daysAfterFirstLaunchBeforeRequest] }
        set { self[.daysAfterFirstLaunchBeforeRequest] = newValue }
    }
    @objc dynamic var firstLaunchDate: Date {
        get { self[.firstLaunchDate] }
        set { self[.firstLaunchDate] = newValue }
    }
    @objc dynamic var keyLabelOption: Int {
        get { self[.keyLabelOption] }
        set { self[.keyLabelOption] = newValue }
    }
    @objc dynamic var keyWidth: Float {
        get { self[.keyWidth] }
        set { self[.keyWidth] = newValue }
    }
    @objc dynamic var lastActivePatch: Data {
        get { self[.lastActivePatch] }
        set { self[.lastActivePatch] = newValue }
    }
    @objc dynamic var lastReviewRequestDate: Date {
        get { self[.lastReviewRequestDate] }
        set { self[.lastReviewRequestDate] = newValue }
    }
    @objc dynamic var lastReviewRequestVersion: String {
        get { self[.lastReviewRequestVersion] }
        set { self[.lastReviewRequestVersion] = newValue }
    }
    @objc dynamic var lowestKeyNote: Int {
        get { self[.lowestKeyNote] }
        set { self[.lowestKeyNote] = newValue}
    }
    @objc dynamic var monthsAfterLastReviewBeforeRequest: Int {
        get { self[.monthsAfterLastReviewBeforeRequest] }
        set { self[.monthsAfterLastReviewBeforeRequest] = newValue }
    }
    @objc dynamic var playSample: Bool {
        get { self[.playSample] }
        set { self[.playSample] = newValue }
    }
    @objc dynamic var copyFilesWhenAdding: Bool {
        // TODO: remove when copyFiles support is done
        get { self[.copyFilesWhenAdding] || false }
        set { self[.copyFilesWhenAdding] = newValue }
    }
    @objc dynamic var showingFavorites: Bool {
        get { self[.showingFavorites] }
        set { self[.showingFavorites] = newValue }
    }
    @objc dynamic var showSolfegeLabel: Bool {
        get { self[.showSolfegeLabel] }
        set { self[.showSolfegeLabel] = newValue }
    }
    @objc dynamic var slideKeyboard: Bool {
        get { self[.slideKeyboard] }
        set { self[.slideKeyboard] = newValue }
    }
    @objc dynamic var midiChannel: Int {
        get { self[.midiChannel] }
        set { self[.midiChannel] = newValue }
    }
    @objc dynamic var reverbPreset: Int {
        get { self[.reverbPreset] }
        set { self[.reverbPreset] = newValue }
    }
    @objc dynamic var reverbMix: Float {
        get { self[.reverbMix] }
        set { self[.reverbMix] = newValue }
    }
    @objc dynamic var showEffects: Bool {
        get { self[.showEffects] }
        set { self[.showEffects] = newValue }
    }
}
