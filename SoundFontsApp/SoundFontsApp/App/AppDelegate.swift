// Copyright © 2018 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework
import UIKit
import os

/// Delegate for the SoundFonts app.
@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, Tasking {
  private lazy var log = Logging.logger("AppDelegate")
  private let components = Components<MainViewController>(inApp: true)
  private var observer: NSObjectProtocol?

  /// The window used to present the app’s visual content on the device’s main screen.
  var window: UIWindow?

  /**
   Set the main view controller for the application. Initiates the configuration process for all of the components
   in the application.

   - parameter mainViewController: the view controller to use
   */
  func setMainViewController(_ mainViewController: MainViewController) {
    if ProcessInfo.processInfo.arguments.contains("-ui_testing") {
      mainViewController.skipTutorial = true
    }
    window?.tintColor = UIColor.systemTeal
    components.setMainViewController(mainViewController)
  }

  /**
   Notification handler for when the application starts.

   - parameter application: the application that is running
   - parameter launchOptions: the options used to start the application
   */
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    observer = NotificationCenter.default.addObserver(forName: .visitAppStore, object: nil,
                                                      queue: nil) { [weak self] _ in
      self?.visitAppStore()
    }
    return true
  }

  /**
   Notification handler for when the application is given an SF2 URL to open.

   - parameter app: the app that is running
   - parameter url: the URL of the file to open
   - parameter options: dictionary of options that may affect the opening (unused)
   */
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    Self.onMain { self.components.fontsViewManager.addSoundFonts(urls: [url]) }
    return true
  }

  /**
   Notification handler for when the application is no longer the active foreground application. Stops audio output.

   - parameter app: the app that is running
   */
  func applicationWillResignActive(_ application: UIApplication) {
    os_log(.debug, log: log, "applicationWillResignActive")
    components.mainViewController.stopAudio()
    NotificationCenter.default.post(Notification(name: .appResigningActive))
  }

  /**
   Notification handler for when the application is running in the background.

   - parameter app: the app that is running
   */
  func applicationDidEnterBackground(_ application: UIApplication) {
    os_log(.debug, log: log, "applicationDidEnterBackground")
  }

  /**
   Notification handler for when the application is running in the foreground.

   - parameter app: the app that is running
   */
  func applicationWillEnterForeground(_ application: UIApplication) {
    os_log(.debug, log: log, "applicationWillEnterForeground")
  }

  /**
   Notification handler for when the application becomes the active foreground application. Starts audio output.

   - parameter app: the app that is running
   */
  func applicationDidBecomeActive(_ application: UIApplication) {
    os_log(.debug, log: log, "applicationDidBecomeActive")
    UIApplication.shared.isIdleTimerDisabled = true
    components.mainViewController.startAudio()
  }

  /**
   Notification handler for when the application is being terminated. Stops audio output.

   - parameter app: the app that is running
   */
  func applicationWillTerminate(_ application: UIApplication) {
    os_log(.debug, log: log, "applicationWillTerminate")
    components.mainViewController.stopAudio()
  }

  func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
    false
  }

  @objc private func visitAppStore() {
    guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1453325077?action=write-review") else {
      fatalError("Expected a valid URL")
    }
    UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
  }
}
