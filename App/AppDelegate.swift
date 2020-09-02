// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit
import SoundFontsFramework
import os

/**
 Delegate for the SoundFonts app.
 */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let log = Logging.logger("AppDel")
    private let components = Components<MainViewController>(changer: .application)
    private var observers: [NSObjectProtocol] = []

    var window: UIWindow?

    func setMainViewController(_ mainViewController: MainViewController) {
        components.setMainViewController(mainViewController)
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch let error as NSError {
            fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        observers.append(NotificationCenter.default.addObserver(forName: .soundFontsCollectionLoadFailure,
                                                                object: nil, queue: nil) { notification in
                                                                    self.notify(notification)
        })

        observers.append(NotificationCenter.default.addObserver(forName: .favoritesCollectionLoadFailure,
                                                                object: nil, queue: nil) { notification in
                                                                    self.notify(notification)
        })

        observers.append(NotificationCenter.default.addObserver(forName: .visitAppStore, object: nil,
                                                                queue: nil) { _ in
            self.visitAppStore()
        })

        return true
    }

    func notify(_ notification: Notification) {
        // let path: URL = notification.object as! URL
        let alert: UIAlertController = {
            switch notification.name {
            case .soundFontsCollectionLoadFailure:
                return UIAlertController(
                    title: "Startup Failure",
                    message: "Unable to load the last saved sound font collection information. Starting from scratch.",
                    preferredStyle: .alert)

            case .favoritesCollectionLoadFailure:
                return UIAlertController(
                    title: "Startup Failure",
                    message: "Unable to load the last saved favorites information. Starting from scratch.",
                    preferredStyle: .alert)

            default:
                fatalError("unexpected notification - \(notification.name)")
            }
        }()

        post(alert: alert)
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        DispatchQueue.main.async {
            self.addSoundFont(url: url)
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

    @objc func visitAppStore() {
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1453325077?action=write-review")
        // guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1453325077")
            else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
}

extension AppDelegate {

    private func addSoundFont(url: URL) {
        let alert: UIAlertController = {
            switch components.soundFonts.add(url: url) {
            case .success(let (_, soundFont)):
                return UIAlertController(
                    title: "SoundFont Added",
                    message: "New SoundFont added under the name '\(soundFont.displayName)'",
                    preferredStyle: .alert)
            case .failure(let failure):
                let reason: String = {
                    switch failure {
                    case .emptyFile: return "Download file first before adding."
                    case .invalidSoundFont: return "Invalid SF2 file contents."
                    case .unableToCreateFile: return "Unable to save the SF2 file to app storage."
                    }
                }()
                return UIAlertController(
                    title: "SoundFont Failure",
                    message: "Failed to add SoundFont. " + reason,
                    preferredStyle: .alert)
            }
        }()

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        post(alert: alert)
    }

    public func post(alert: UIAlertController) {
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
