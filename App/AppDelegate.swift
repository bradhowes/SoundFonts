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
    private let components =
        Components<MainViewController>(sharedStateMonitor: SharedStateMonitor(changer: .application))

    var window: UIWindow?

    func setMainViewController(_ mainViewController: MainViewController) {
        components.setMainViewController(mainViewController)
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default,
                                         options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
        } catch let error as NSError {
            fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        return true
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
}

extension AppDelegate {

    private func addSoundFont(url: URL) {
        let alert: UIAlertController = {
            if let (_, soundFont) = components.soundFonts.add(url: url) {
                let alert = UIAlertController(
                    title: "SoundFont Added",
                    message: "New SoundFont added under the name '\(soundFont.displayName)'",
                    preferredStyle: .alert)
                return alert
            }
            else {
                let alert = UIAlertController(
                    title: "SoundFont Failure",
                    message: "Failed to add new SoundFont.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                return alert
            }
        }()

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
