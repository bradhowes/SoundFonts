// Copyright © 2019 Brad Howes. All rights reserved.

import UIKit

public extension UserDefaults {

    /**
     Obtain an NSNumber value from UserDefaults

     - parameter key: the name of the setting to return
     - returns: optional NSNumber instance holding the value
     */
    func number(forKey key: String) -> NSNumber? { object(forKey: key) as? NSNumber }

    /**
     Determine if UserDefaults contains a key under the given name

     - parameter key: the SettingKey to look for
     - returns: true if found
     */
    func hasKey<T>(_ key: SettingKey<T>) -> Bool { object(forKey: key.userDefaultsKey) != nil }

    /**
     Remove the setting from UserDefaults

     - parameter key: the SettingKey to remove
     */
    func remove<T>(_ key: SettingKey<T>) { removeObject(forKey: key.userDefaultsKey) }

    /**
     Enable subscripting by SettingKey instances.

     - parameter key: SettingKey instance to use as a key into UserDefaults
     - returns: instance of the tempalte type from UserDefaults or the configured default value if it did not exist.
     */
    subscript<T>(key: SettingKey<T>) -> T where T: SettingSerializable {
        get { T.get(key: key.userDefaultsKey, userDefaults: self) ?? key.defaultValue }
        set { T.set(key: key.userDefaultsKey, value: newValue, userDefaults: self) }
    }
}

public extension UserDefaults {

    static let daysAfterFirstLaunchBeforeRequest = SettingKey<Int>("daysAfterFirstLaunchBeforeRequest", defaultValue: 14)
    static let firstLaunchDate = SettingKey<Date>("firstLaunchDate", defaultValue: Date.distantPast)
    static let keyLabelOption = SettingKey<Int>("keyLabelOption", defaultValue: -1)
    static let keyWidth = SettingKey<Float>("keyWidth", defaultValue: 64.0)
    static let lastActivePatch = SettingKey("lastActivePatch", defaultValue: Data())
    static let lastReviewRequestDate = SettingKey<Date>("lastReviewRequestDate", defaultValue: Date.distantPast)
    static let lastReviewRequestVersion = SettingKey<String>("lastReviewRequestVersion", defaultValue: "")
    static let lowestKeyNote = SettingKey<Int>("lowestKeyNote", defaultValue: 48)
    static let monthsAfterLastReviewBeforeRequest = SettingKey<Int>("monthsAfterLastReviewBeforeRequest", defaultValue: 2)
    static let playSample = SettingKey<Bool>("playSample", defaultValue: false)
    static let showKeyLabels = SettingKey<Bool>("showKeyLabels", defaultValue: false)
    static let showingFavorites = SettingKey<Bool>("showingFavorites", defaultValue: false)
    static let showSolfegeLabel = SettingKey<Bool>("showSolfegeLabel", defaultValue: true)

    @objc dynamic var daysAfterFirstLaunchBeforeRequest: Int {
        get { self[Self.daysAfterFirstLaunchBeforeRequest] }
        set { self[Self.daysAfterFirstLaunchBeforeRequest] = newValue }
    }
    @objc dynamic var firstLaunchDate: Date {
        get { self[Self.firstLaunchDate] }
        set { self[Self.firstLaunchDate] = newValue }
    }
    @objc dynamic var keyLabelOption: Int {
        get { self[Self.keyLabelOption] }
        set { self[Self.keyLabelOption] = newValue }
    }
    @objc dynamic var keyWidth: Float {
        get { self[Self.keyWidth] }
        set { self[Self.keyWidth] = newValue }
    }
    @objc dynamic var lastActivePatch: Data {
        get { self[Self.lastActivePatch] }
        set { self[Self.lastActivePatch] = newValue }
    }
    @objc dynamic var lastReviewRequestDate: Date {
        get { self[Self.lastReviewRequestDate] }
        set { self[Self.lastReviewRequestDate] = newValue }
    }
    @objc dynamic var lastReviewRequestVersion: String {
        get { self[Self.lastReviewRequestVersion] }
        set { self[Self.lastReviewRequestVersion] = newValue }
    }
    @objc dynamic var lowestKeyNote: Int {
        get { self[Self.lowestKeyNote] }
        set { self[Self.lowestKeyNote] = newValue}
    }
    @objc dynamic var monthsAfterLastReviewBeforeRequest: Int {
        get { self[Self.monthsAfterLastReviewBeforeRequest] }
        set { self[Self.monthsAfterLastReviewBeforeRequest] = newValue }
    }
    @objc dynamic var playSample: Bool {
        get { self[Self.playSample] }
        set { self[Self.playSample] = newValue }
    }
    @objc dynamic var showKeyLabels: Bool {
        get { self[Self.showKeyLabels] }
        set { self[Self.showKeyLabels] = newValue }
    }
    @objc dynamic var showingFavorites: Bool {
        get { self[Self.showingFavorites] }
        set { self[Self.showingFavorites] = newValue }
    }
    @objc dynamic var showSolfegeLabel: Bool {
        get { self[Self.showSolfegeLabel] }
        set { self[Self.showSolfegeLabel] = newValue }
    }
}
