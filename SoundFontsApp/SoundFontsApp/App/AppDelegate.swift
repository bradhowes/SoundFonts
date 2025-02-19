// Copyright © 2018 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework
import UIKit
import os

/// Delegate for the SoundFonts app.
@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  private lazy var log: Logger = Logging.logger("AppDelegate")
  private let components = Components<MainViewController>.make(
    inApp: true,
    identity: RandomWords.uniqueIdentifier
  )

  private var observer: NSObjectProtocol?
  private var pendingAddition: URL?
  private var configObserver: ConsolidatedConfigObserver?

  /// The window used to present the app’s visual content on the device’s main screen.
  var window: UIWindow?

  /**
   Set the main view controller for the application. Initiates the configuration process for all of the components
   in the application. Interrogates the startup command-line arguments and if `ui_testing` is present, it disables
   showing the tutorial.

   - parameter mainViewController: the view controller to use
   */
  func setMainViewController(_ mainViewController: MainViewController) {
    if ProcessInfo.processInfo.arguments.contains("-ui_testing") {
      mainViewController.skipTutorial = true
    }
    window?.tintColor = UIColor.systemTeal
    components.setMainViewController(mainViewController)

    // Monitor the config value -- when it changes to non-nil, we have opened/reopened the config file and loaded it.
    // If there is a pending URL to a sound font to add, do it.
    configObserver = ConsolidatedConfigObserver(configProvider: components.consolidatedConfigProvider) { [weak self] in
      guard let self = self else { return }
      if let _ = self.components.consolidatedConfigProvider.config,
         let toAdd = self.pendingAddition {
        self.pendingAddition = nil
        self.components.fontsViewManager.addSoundFonts(urls: [toAdd])
      }
    }
  }

  /**
   Notification handler for when the application starts. Handles requests to visit the AppStore and view the SoundFonts
   page there.

   - parameter application: the application that is running
   - parameter launchOptions: the options used to start the application
   */
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    observer = NotificationCenter.default.addObserver(
      forName: .visitAppStore,
      object: nil,
      queue: nil
    ) { [weak self] _ in
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
  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    pendingAddition = url
    return true
  }

  /**
   Notification handler for when the application is no longer the active foreground application. Stops audio output.

   - parameter app: the app that is running
   */
  func applicationWillResignActive(_ application: UIApplication) {
    log.debug("applicationWillResignActive")
    if !components.settings.backgroundMIDIProcessingEnabled {
      components.mainViewController.stopAudio()
    }
  }

  /**
   Notification handler for when the application is running in the background.

   - parameter app: the app that is running
   */
  func applicationDidEnterBackground(_ application: UIApplication) {
    log.debug("applicationDidEnterBackground")
  }

  /**
   Notification handler for when the application is running in the foreground.

   - parameter app: the app that is running
   */
  func applicationWillEnterForeground(_ application: UIApplication) {
    log.debug("applicationWillEnterForeground")
  }

  /**
   Notification handler for when the application becomes the active foreground application. Starts audio output.

   - parameter app: the app that is running
   */
  func applicationDidBecomeActive(_ application: UIApplication) {
    log.debug("applicationDidBecomeActive")
    UIApplication.shared.isIdleTimerDisabled = true
    components.mainViewController.startAudioSession()
  }

  /**
   Notification handler for when the application is being terminated. Stops audio output.

   - parameter app: the app that is running
   */
  func applicationWillTerminate(_ application: UIApplication) {
    log.debug("applicationWillTerminate")
    components.mainViewController.stopAudio()
  }

  func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
    false
  }

  private func visitAppStore() {
    if let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1453325077?action=write-review") {
      UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
  }
}
