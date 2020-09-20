// Copyright © 2020 Brad Howes. All rights reserved.

import StoreKit
import os

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
