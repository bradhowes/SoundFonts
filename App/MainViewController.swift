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

    private var keyboard: Keyboard!
    private var infoBar: InfoBar!
    private var activePatchManager: ActivePatchManager!
    private var notePlayer: NotePlayer!
    private var volumeMonitor: VolumeMonitor!
    private var sampler: Sampler!

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.appDelegate.setMainViewController(self)
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

        useActivePatchKind(activePatchManager.active, playSample: false)
    }

    /**
     Stop audio processing. This is done prior to the app moving into the background.
     */
    func stopAudio() {
        sampler.stop()
        volumeMonitor.stop()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: [])
            os_log(.info, log: log, "set audio session inactive")
        } catch let error as NSError {
            os_log(.error, log: log, "Failed setActive(false): %{public}s", error.localizedDescription)
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
        sampler = router.sampler
        activePatchManager = router.activePatchManager
        keyboard = router.keyboard
        infoBar = router.infoBar

        notePlayer = NotePlayer(infoBar: infoBar, sampler: sampler)
        keyboard.delegate = notePlayer!
        volumeMonitor = VolumeMonitor(keyboard: keyboard, notePlayer: notePlayer, sampler: sampler)

        activePatchManager.subscribe(self, notifier: activePatchChange)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new, playSample: playSample) = event {
            useActivePatchKind(new, playSample: playSample)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind, playSample: Bool) {
        keyboard.releaseAllKeys()
        DispatchQueue.global(qos: .userInitiated).async {
            if case let .failure(what) = self.sampler.load(activePatchKind: activePatchKind, playSample: playSample) {
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
