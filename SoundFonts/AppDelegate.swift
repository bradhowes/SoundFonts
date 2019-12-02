// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var mainViewController: MainViewController?
    let soundFontLibrary = SoundFontLibrary.shared
    let favoriteCollection = FavoriteCollection.shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("application didFinishLaunchingWithOptions")

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch let error as NSError {
            fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("-- given: \(url)")
        let soundFont = soundFontLibrary.add(url: url)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
        mainViewController?.stopAudio()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive")
        mainViewController?.startAudio()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate")
        mainViewController?.stopAudio()
    }
}

