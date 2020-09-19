// Copyright © 2020 Brad Howes. All rights reserved.

import StoreKit
import os

extension UserDefaults {
    static let daysAfterFirstLaunchBeforeRequest = SettingKey<Int>("daysAfterFirstLaunchBeforeRequest",
                                                                   defaultValue: 14)
    static let monthsAfterLastReviewBeforeRequest = SettingKey<Int>("monthsAfterLastReviewBeforeRequest",
                                                                    defaultValue: 2)

    static let firstLaunchDate = SettingKey<Date>("firstLaunchDate", defaultValue: Date.distantPast)
    static let lastReviewRequestDate = SettingKey<Date>("lastReviewRequestDate", defaultValue: Date.distantPast)
    static let lastReviewRequestVersion = SettingKey<String>("lastReviewRequestVersion", defaultValue: "")

    @objc dynamic var daysAfterFirstLaunchBeforeRequest: Int {
        get { self[Self.daysAfterFirstLaunchBeforeRequest] }
        set { self[Self.daysAfterFirstLaunchBeforeRequest] = newValue }
    }

    @objc dynamic var monthsAfterLastReviewBeforeRequest: Int {
        get { self[Self.monthsAfterLastReviewBeforeRequest] }
        set { self[Self.monthsAfterLastReviewBeforeRequest] = newValue }
    }

    @objc dynamic var firstLaunchDate: Date {
        get { self[Self.firstLaunchDate] }
        set { self[Self.firstLaunchDate] = newValue }
    }

    @objc dynamic var lastReviewRequestDate: Date {
        get { self[Self.lastReviewRequestDate] }
        set { self[Self.lastReviewRequestDate] = newValue }
    }

    @objc dynamic var lastReviewRequestVersion: String {
        get { self[Self.lastReviewRequestVersion] }
        set { self[Self.lastReviewRequestVersion] = newValue }
    }
}

public final class AskForReview: NSObject {

    private let log = Logging.logger("AskR")

    static public func maybe() { NotificationCenter.default.post(Notification(name: .askForReview)) }

    /// Obtain the version found in the main bundle.
    let currentVersion: String = {
        //swiftlint:disable force_cast
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        //swiftlint:enable force_cast
    }()

    /// Obtain the first time the app was launched by the user after installing.
    let firstLaunchDate: Date = {
        var value = settings.firstLaunchDate
        if value == Date.distantPast {
            value = Date()
            settings.firstLaunchDate = value
        }
        return value
    }()

    /// Obtain the time when the app was last reviewed. If never, then this will be `Date.distantPast`
    var lastReviewRequestDate: Date = settings.lastReviewRequestDate {
        didSet { settings.lastReviewRequestDate = lastReviewRequestDate }
    }

    /// Obtain the time when the app was last reviewed. If never, then this will be `Date.distantPast`
    var lastReviewRequestVersion: String = settings.lastReviewRequestVersion {
        didSet { settings.lastReviewRequestVersion = lastReviewRequestVersion }
    }

    /// Get the date N days days since the first launch
    lazy var dateSinceFirstLaunch: Date = Calendar.current.date(
        byAdding: .day,
        value: settings.daysAfterFirstLaunchBeforeRequest,
        to: firstLaunchDate)!

    /// Get the date N months since the last review request
    lazy var dateSinceLastReviewRequest: Date = Calendar.current.date(
        byAdding: .month,
        value: settings.monthsAfterLastReviewBeforeRequest,
        to: lastReviewRequestDate)!

    var countDown = 3

    public init(isMain: Bool) {
        super.init()
        os_log(.info, log: log, "init: dateSinceFirstLaunch - %s  dateSinceLastReviewRequest - %s",
               dateSinceFirstLaunch.description, dateSinceLastReviewRequest.description)
        if isMain {
            NotificationCenter.default.addObserver(forName: .askForReview, object: nil, queue: nil) { _ in self.ask() }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     Ask user for a review. Whether the ask actually happens depends on *when* this method is called:

     - must be at least 14 days since the app was first launched
     - must be at least 2 months since the last review request
     - version of the app must be different than the last version
     */
    public func ask() {
        os_log(.info, log: log, "ask")

        let now = Date()
        let currentVersion = self.currentVersion
        guard currentVersion != self.lastReviewRequestVersion else {
            os_log(.info, log: log, "same version as last review request")
            return
        }

        guard now >= dateSinceFirstLaunch else {
            os_log(.info, log: log, "too soon after first launch")
            return
        }

        guard now >= dateSinceLastReviewRequest else {
            os_log(.info, log: log, "too soon after last review request")
            return
        }

        guard countDown < 1 else {
            countDown -= 1
            os_log(.info, log: log, "too soon after launching")
            return
        }

        DispatchQueue.main.async {
            SKStoreReviewController.requestReview()
            self.lastReviewRequestVersion = currentVersion
            self.lastReviewRequestDate = now
        }
    }
}
