// Copyright © 2020 Brad Howes. All rights reserved.

import StoreKit
import os

/// Manages when to ask the user for an app review. Relies on SKStoreReviewController.requestReview to do the actual
/// review prompt, but makes sure that the interval between asks is reasonable and within App Store policy.
public final class AskForReview: NSObject {
  private lazy var log: Logger = Logging.logger("AskForReview")

  /**
   Class method that fires a notification to ask for a review check. When running as an application, there should be
   an AskForReview instance listening for the notification which will perform the actual review request. Otherwise,
   the notification just goes off in to space...
   */
  static public func maybe() { NotificationCenter.default.post(Notification(name: .askForReview)) }

  private let settings: Settings

  /// Obtain the version found in the main bundle.
  private lazy var currentVersion: String = {
    guard
      let version = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
        as? String
    else {
      fatalError()
    }
    return version
  }()

  /// Obtain the first time the app was launched by the user after installing.
  private lazy var firstLaunchDate: Date = {
    var value = settings.firstLaunchDate
    if value == Date.distantPast {
      value = Date()
      settings.firstLaunchDate = value
    }
    return value
  }()

  /// Obtain the time when the app was last reviewed. If never, then this will be `Date.distantPast`
  private lazy var lastReviewRequestDate: Date = settings.lastReviewRequestDate {
    didSet { settings.lastReviewRequestDate = lastReviewRequestDate }
  }

  /// Obtain the time when the app was last reviewed. If never, then this will be `Date.distantPast`
  private lazy var lastReviewRequestVersion: String = settings.lastReviewRequestVersion {
    didSet { settings.lastReviewRequestVersion = lastReviewRequestVersion }
  }

  /// Get the date N days days since the first launch
  private lazy var dateSinceFirstLaunch: Date =
    Calendar.current.date(
      byAdding: .day,
      value: settings.daysAfterFirstLaunchBeforeRequest,
      to: firstLaunchDate
    ) ?? Date()

  /// Get the date N months since the last review request
  private lazy var dateSinceLastReviewRequest: Date =
    Calendar.current.date(
      byAdding: .month,
      value: settings.monthsAfterLastReviewBeforeRequest,
      to: lastReviewRequestDate
    ) ?? Date()

  private var countDown = 3
  private var observer: NSObjectProtocol?
  public var windowScene: UIWindowScene?

  /**
   Construct new (sole) instance

   - parameter settings: source of user/app settings
   */
  public init(settings: Settings) {
    self.settings = settings
    super.init()
    observer = NotificationCenter.default.addObserver(forName: .askForReview, object: nil, queue: nil) { [weak self] _ in
      self?.ask()
    }
  }

  /**
   Ask user for a review. Whether the ask actually happens depends on *when* this method is called:

   - must be at least 14 days since the app was first launched
   - must be at least 2 months since the last review request
   - version of the app must be different than the last version
   */
  public func ask() {
    log.debug("ask")

    let now = Date()
    let currentVersion = self.currentVersion
    guard currentVersion != self.lastReviewRequestVersion else {
      log.debug("same version as last review request")
      return
    }

    guard now >= dateSinceFirstLaunch else {
      log.debug("too soon after first launch")
      return
    }

    guard now >= dateSinceLastReviewRequest else {
      log.debug("too soon after last review request")
      return
    }

    guard countDown < 1 else {
      countDown -= 1
      log.debug("too soon after launching")
      return
    }

    DispatchQueue.main.async {
      guard let windowScene = self.windowScene else { return }
      SKStoreReviewController.requestReview(in: windowScene)
      self.lastReviewRequestVersion = currentVersion
      self.lastReviewRequestDate = now
    }
  }
}
