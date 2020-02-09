// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit
import os
import SoundFontsFramework

/**
 Top-level view controller for the application. It contains the Sampler which will emit sounds based on what keys are
 touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
 to the background or stops being active.
 */
final class MainViewController: UIViewController {
    private lazy var log = Logging.logger("MainVC")
    private lazy var sampler = Sampler(mode: .standalone)

    private var keyboard: Keyboard!
    private var infoBar: InfoBar!
    private var activePatchManager: ActivePatchManager!
    private var notePlayer: NotePlayer!
    private var volumeMonitor: VolumeMonitor!

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.appDelegate.components.addMainController(self)
        UIApplication.shared.appDelegate.mainViewController = self
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }
}

extension MainViewController {

    /**
     Start audio processing. This is done as the app is brought into the foreground.
     */
    func startAudio() {

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: [])
            os_log(.info, log: log, "set active audio session")
        } catch let error as NSError {
            os_log(.error, log: log, "Failed setActive(true): %s", error.localizedDescription)
        }

        volumeMonitor.start(session: session)

        if case let .failure(what) = sampler.start() {
            postAlert(for: what)
        }

        useActivePatchKind(activePatchManager.active)
    }

    /**
     Stop audio processing. This is done prior to the app moving into the background.
     */
    func stopAudio() {
        sampler.stop()

        let session = AVAudioSession.sharedInstance()
        volumeMonitor.stop(session: session)

        do {
            try session.setActive(false, options: [])
            os_log(.info, log: log, "set audio session inactive")
        } catch let error as NSError {
            os_log(.error, log: log, "Failed setActive(false): %s", error.localizedDescription)
        }
    }
}

// MARK: - Controller Configuration

extension MainViewController: ControllerConfiguration {

    /**
     Establish connections with other managers / controllers.

     - parameter context: the RunContext that holds all of the registered managers / controllers
     */
    func establishConnections(_ router: ComponentContainer) {
        activePatchManager = router.activePatchManager
        keyboard = router.keyboard
        infoBar = router.infoBar

        notePlayer = NotePlayer(infoBar: infoBar, sampler: sampler)
        keyboard.delegate = notePlayer!
        volumeMonitor = VolumeMonitor(keyboard: keyboard, notePlayer: notePlayer)

        activePatchManager.subscribe(self, closure: activePatchChange)
        router.favorites.subscribe(self, closure: favoritesChange)
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
        case let .removed(index: _, favorite: favorite, bySwiping: _): updateInfoBar(with: favorite.soundFontPatch)
        default: break
        }
    }

    private func updateInfoBar(with favorite: Favorite) {
        if activePatchManager.soundFontPatch == favorite.soundFontPatch {
            infoBar.setPatchInfo(name: favorite.name, isFavored: true)
        }
    }

    private func updateInfoBar(with soundFontPatch: SoundFontPatch) {
        if activePatchManager.soundFontPatch == soundFontPatch {
            infoBar.setPatchInfo(name: soundFontPatch.patch.name, isFavored: false)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind) {
        if let favorite = activePatchKind.favorite {
            updateInfoBar(with: favorite)
        }
        else {
            updateInfoBar(with: activePatchKind.soundFontPatch)
        }

        keyboard.releaseAllKeys()
        DispatchQueue.global(qos: .userInitiated).async {
            if case let .failure(what) = self.sampler.load(activePatchKind: activePatchKind) {
                DispatchQueue.main.async { self.postAlert(for: what) }
            }
        }
    }

    private func postAlert(for what: Sampler.Failure) {
        let alertController = UIAlertController(title: "Sampler Issue",
                                                message: "Unexpected problem with the audio sampler.",
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in }
        alertController.addAction(cancel)

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY,
                                                  width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        self.present(alertController, animated: true, completion: nil)
    }

}
