// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit
import SoundFontsFramework
import os

/**
 Delegate for the SoundFonts app.
 */
@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let log = Logging.logger("AppDel")
    private lazy var components = Components<MainViewController>(inApp: true)
    private var observer: NSObjectProtocol?
    var window: UIWindow?

    func setMainViewController(_ mainViewController: MainViewController) {
        window?.tintColor = UIColor.systemTeal
        components.setMainViewController(mainViewController)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        } catch let error as NSError {
            fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        observer = NotificationCenter.default.addObserver(forName: .visitAppStore, object: nil, queue: nil) { _ in self.visitAppStore() }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DispatchQueue.main.async { self.components.patchesViewManager.addSoundFonts(urls: [url]) }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        os_log(.info, log: log, "applicationWillResignActive")
        components.mainViewController.stopAudio()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        os_log(.info, log: log, "applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        os_log(.info, log: log, "applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        os_log(.info, log: log, "applicationDidBecomeActive")
        UIApplication.shared.isIdleTimerDisabled = true
        components.mainViewController.startAudio()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        os_log(.info, log: log, "applicationWillTerminate")
        components.mainViewController.stopAudio()
    }

    @objc private func visitAppStore() {
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1453325077?action=write-review")
        // guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1453325077")
            else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
}
