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

    @IBOutlet private weak var favoritesView: UIView!
    @IBOutlet private weak var patchesView: UIView!

    private lazy var sampler = Sampler()
    private var upperViewManager = UpperViewManager()

    private var patchesViewManager: PatchesViewManager!
    private var activePatchManager: ActivePatchManager!
    private var keyboard: Keyboard!
    private var infoBar: InfoBar!
    private var registeredObserver = false

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    private var volume: Float = 0.0 {
        didSet {
            keyboard.isMuted = isMuted
        }
    }

    private var muted = false {
        didSet {
            keyboard.isMuted = isMuted
        }
    }

    private var isMuted: Bool { volume < 0.01 || muted }

    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        upperViewManager.add(view: patchesView)
        upperViewManager.add(view: favoritesView)
        UIApplication.shared.appDelegate.router.addViewControllers(self, children)
        UIApplication.shared.appDelegate.mainViewController = self
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
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
        registeredObserver = true

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

        useActivePatchKind(activePatchManager.active)
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

        if registeredObserver {
            session.removeObserver(self, forKeyPath: Observation.VolumeKey, context: &Observation.Context)
            registeredObserver = false
        }

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
    func establishConnections(_ router: Router) {

        patchesViewManager = router.patchesViewManager
        activePatchManager = router.activePatchManager
        keyboard = router.keyboard
        infoBar = router.infoBar

        keyboard.delegate = self

        activePatchManager.subscribe(self, closure: activePatchChange)
        router.favorites.subscribe(self, closure: favoritesChange)

        infoBar.addTarget(.doubleTap, target: self, action: #selector(toggleConfigurationViews))

        let showingFavorites = Settings[.wasShowingFavorites]
        patchesView.isHidden = showingFavorites
        favoritesView.isHidden = !showingFavorites

        patchesViewManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        patchesViewManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))

        let favoritesViewManager = router.favoritesViewManager
        favoritesViewManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        favoritesViewManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new) = event {
            useActivePatchKind(new)
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        switch event {
        case let .added(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .changed(index: _, favorite: favorite): updateInfoBar(with: favorite)
        case let .removed(index: _, favorite: favorite, bySwiping: _): updateInfoBar(with: favorite)
        default: break
        }
    }

    private func updateInfoBar(with favorite: Favorite) {
        if favorite.soundFontPatch == activePatchManager.soundFontPatch {
            infoBar.setPatchInfo(name: favorite.name, isFavored: true)
        }
    }

    @IBAction private func toggleConfigurationViews() {
        if favoritesView.isHidden {
            showNextConfigurationView()
        }
        else {
            showPreviousConfigurationView()
        }
    }

    /**
     Show the next (right) view in the space above the info bar.
     */
    @IBAction private func showNextConfigurationView() {
        patchesViewManager.dismissSearchKeyboard()
        Settings[.wasShowingFavorites] = favoritesView.isHidden
        upperViewManager.slideNextHorizontally()
    }

    /**
     Show the previous (left) view in the space above the info bar.
     */
    @IBAction private func showPreviousConfigurationView() {
        patchesViewManager.dismissSearchKeyboard()
        Settings[.wasShowingFavorites] = favoritesView.isHidden
        upperViewManager.slidePrevHorizontally()
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind) {

        if let favorite = activePatchKind.favorite {
            infoBar.setPatchInfo(name: favorite.name, isFavored: true)
        }
        else {
            infoBar.setPatchInfo(name: activePatchKind.soundFontPatch.patch.name, isFavored: false)
        }

        keyboard.releaseAllKeys()
        DispatchQueue.global(qos: .userInitiated).async {
            if case let .failure(what) = self.sampler.load(activePatchKind: activePatchKind) {
                DispatchQueue.main.async { self.postAlert(for: what) }
            }
        }
    }
}

// MARK: - KeyboardManagerDelegate protocol

extension MainViewController : KeyboardDelegate {

    /**
     Play a note with the sampler. Show note info in the info bar.

     - parameter note: the note to play
     */
    func noteOn(_ note: Note) {
        if isMuted {
            infoBar.setStatus("🔇")
        }
        else {
            infoBar.setStatus(note.label + " - " + note.solfege)
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
