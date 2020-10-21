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
    private var observers: [NSObjectProtocol] = []

    var window: UIWindow?

    func setMainViewController(_ mainViewController: MainViewController) {
        for issue in [Notification.Name.soundFontsCollectionLoadFailure,
                      .soundFontsCollectionOrphans,
                      .favoritesCollectionLoadFailure,
                      .soundFontFileAccessDenied] {
            observers.append(NotificationCenter.default.addObserver(forName: issue, object: nil, queue: nil) { notif in
                self.notify(notif)
            })
        }
        components.setMainViewController(mainViewController)
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        } catch let error as NSError {
            fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        observers.append(NotificationCenter.default.addObserver(forName: .visitAppStore, object: nil, queue: nil) { _ in
            self.visitAppStore()
        })

        return true
    }

    func notify(_ notification: Notification) {
        let (title, body): (String, String) = {
            switch notification.name {
            case .soundFontsCollectionLoadFailure:
                return ("Startup Failure", """
Unable to load the last saved sound font collection information. Recreating using found SF2 files, but customizations
have been lost.
""")

            case .favoritesCollectionLoadFailure:
                return ("Startup Failure", "Unable to load the last saved favorites information.")

            case .soundFontsCollectionOrphans:
                guard let count = notification.object as? NSNumber else { fatalError() }
                return ("Orphaned SF2 Files", """
Found \(count.intValue) SF2 files that are not being used and moved them to local SoundFonts folder.
""")

            case .soundFontFileAccessDenied:
                guard let name = notification.object as? String else { fatalError() }
                return ("Access Failure", "Unable to access and use the sound font file '\(name)'.")

            default:
                fatalError("unexpected notification - \(notification.name)")
            }
        }()

        AlertManager.shared.post(alert: AlertConfig(title: title, message: body))
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DispatchQueue.main.async {
            self.components.patchesViewManager.addSoundFonts(urls: [url])
        }
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
