// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit
import os

extension SettingKeys {
    static let wasShowingFavorites = SettingKey<Bool>("showingFavorites", defaultValue: false)
}

/**
 Top-level view controller for the application. It contains the Sampler which will emit sounds based on what keys are
 touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
 to the background or stops being active.
 */
final class MainViewController: UIViewController {
    private lazy var logger = Logging.logger("MainVC")

    @IBOutlet private weak var patches: UIView!
    @IBOutlet private weak var favorites: UIView!

    private lazy var sampler = Sampler()
    private var upperViewManager = UpperViewManager()
    private var patchesManager: PatchesManager!

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    private var volume: Float = 0.0 {
        didSet {
            KeyboardRender.isMuted = isMuted
        }
    }

    private var muted = false {
        didSet {
            KeyboardRender.isMuted = isMuted
        }
    }

    private var isMuted: Bool { volume < 0.01 || muted }

    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        upperViewManager.add(view: patches)
        upperViewManager.add(view: favorites)
        runContext.addViewControllers(self, children)
        runContext.establishConnections()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        print("MainViewController - viewDidLoad")
    }

    override func viewDidAppear(_ animated: Bool) {
        print("MainViewController - viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        print("MainViewController - viewWillDisappear")
    }
}

extension MainViewController {

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if context == &Observation.Context {
            if keyPath == Observation.VolumeKey {
                if let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue {
                    self.volume = volume
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    /**
     Start audio processing. This is done as the app is brought into the foreground.
     */
    func startAudio() {
        let session = AVAudioSession.sharedInstance()
        session.addObserver(self, forKeyPath: Observation.VolumeKey, options: [.initial, .new],
                            context: &Observation.Context)

        do {
            try session.setActive(true, options: [])
            print("MainViewController - set active audio session")
        } catch let error as NSError {
            fatalError("Failed setActive(true): \(error.localizedDescription)")
        }

        Mute.shared.notify = {muted in self.muted = muted }
        Mute.shared.isPaused = false

        if case let .failure(what) = sampler.start() {
            postAlert(for: what)
        }

        setPatch(runContext.activePatchManager.activePatch)
    }

    private func postAlert(for what: Sampler.Failure) {
        let alertController = UIAlertController(title: "Sampler Issue",
                                                message: "Unexpected problem with the audio sampler.",
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style:.cancel) { _ in }
        alertController.addAction(cancel)

        if let popoverController = alertController.popoverPresentationController {
          popoverController.sourceView = self.view
          popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
          popoverController.permittedArrowDirections = []
        }

        self.present(alertController, animated: true, completion: nil)
    }

    /**
     Stop audio processing. This is done prior to the app moving into the background.
     */
    func stopAudio() {
        sampler.stop()

        Mute.shared.notify = nil
        Mute.shared.isPaused = true

        let session = AVAudioSession.sharedInstance()
        session.removeObserver(self, forKeyPath: Observation.VolumeKey, context: &Observation.Context)

        do {
            try session.setActive(false, options: [])
            print("MainViewController - set inactive audio session")
        } catch let error as NSError {
            print("Failed setActive(false): \(error.localizedDescription)")
        }
    }

}

// MARK: - Controller Configuration

extension MainViewController: ControllerConfiguration {

    /**
     Establish connections with other managers / controllers.

     - parameter context: the RunContext that holds all of the registered managers / controllers
     */
    func establishConnections(_ context: RunContext) {
        (UIApplication.shared.delegate as? AppDelegate)?.mainViewController = self
        context.keyboardManager.delegate = self
        context.activePatchManager.addPatchChangeNotifier(self) { _, patch in self.setPatch(patch) }
        context.favoritesManager.addFavoriteChangeNotifier(self) { _, favorite in self.useFavorite(favorite) }
        context.infoBarManager.addTarget(.doubleTap, target: self, action: #selector(showNextConfigurationView))

        let showingFavorites = Settings[.wasShowingFavorites]
        self.patches.isHidden = showingFavorites
        self.favorites.isHidden = !showingFavorites

        self.patchesManager = context.patchesManager
        patchesManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        patchesManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))

        context.favoritesManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        context.favoritesManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))
    }

    /**
     Show the next (right) view in the space above the info bar.
     */
    @IBAction private func showNextConfigurationView() {
        patchesManager.dismissSearchKeyboard()
        Settings[.wasShowingFavorites] = favorites.isHidden
        upperViewManager.slideNextHorizontally()
    }

    /**
     Show the previous (left) view in the space above the info bar.
     */
    @IBAction private func showPreviousConfigurationView() {
        patchesManager.dismissSearchKeyboard()
        Settings[.wasShowingFavorites] = favorites.isHidden
        upperViewManager.slidePrevHorizontally()
    }

    private func setPatch(_ patch: Patch) {
        runContext.keyboardManager.releaseAllKeys()
        runContext.infoBarManager.setPatchInfo(name: patch.name,
                                               isFavored: runContext.favoritesManager.isFavored(patch: patch))

        // The loading of the patch tasks some time, so do it on a background thread. Not sure if this is really
        // desirable since there is no sound until the sampler is finished loading.
        DispatchQueue.global(qos: .userInitiated).async {
            if case let .failure(what) = self.sampler.load(patch: patch) {
                DispatchQueue.main.async {
                    self.postAlert(for: what)
                }
            }
            else {
                Settings[.lastActiveSoundFont] = patch.soundFont.uuid.uuidString
                Settings[.lastActivePatch] = patch.index
            }
        }
    }

    private func useFavorite(_ favorite: Favorite) {
        if favorite.patch == runContext.activePatchManager.activePatch {
            let patch = favorite.patch
            runContext.infoBarManager.setPatchInfo(name: patch.name,
                                                   isFavored: runContext.favoritesManager.isFavored(patch: patch))
            DispatchQueue.global(qos: .background).async {
                self.sampler.setGain(favorite.gain)
                self.sampler.setPan(favorite.pan)
            }
        }
    }
}

// MARK: - KeyboardManagerDelegate protocol

extension MainViewController : KeyboardManagerDelegate {

    /**
     Play a note with the sampler. Show note info in the info bar.

     - parameter note: the note to play
     */
    func noteOn(_ note: Note) {
        if isMuted {
            runContext.infoBarManager.setStatus("🔇")
        }
        else {
            runContext.infoBarManager.setStatus(note.label + " - " + note.solfege)
            sampler.noteOn(note.midiNoteValue)
        }
    }

    /**
     Stop playing a note with the sampler.

     - parameter note: the note to stop.
     */
    func noteOff(_ note: Note) {
        sampler.noteOff(note.midiNoteValue)
    }
}
