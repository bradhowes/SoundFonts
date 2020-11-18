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
    private var activePatchManager: ActivePatchManager!
    private var sampler: Sampler!
    private var volumeMonitor: VolumeMonitor?
    private let midi = MIDI()

    fileprivate var noteInjector = NoteInjector()

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.appDelegate.setMainViewController(self)
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in InfoHUD.clear() }, completion: { _ in self.volumeMonitor?.repostNotice() })
    }
}

extension MainViewController {

    /**
     Start audio processing. This is done as the app is brought into the foreground.
     */
    func startAudio() {
        DispatchQueue.global(qos: .userInitiated).async { self.startAudioBackground() }
    }

    private func startAudioBackground() {
        let session = AVAudioSession.sharedInstance()
        do {
            os_log(.info, log: log, "setting active audio session")
            try session.setActive(true, options: [])
            os_log(.info, log: log, "starting sampler")
            let result = sampler.start()
            DispatchQueue.main.async { self.finishStart(result) }
        } catch let error as NSError {
            let result: SamplerStartFailure = .sessionActivating(error: error)
            os_log(.error, log: log, "Failed session.setActive(true): %{public}s", error.localizedDescription)
            DispatchQueue.main.async { self.finishStart(.failure(result)) }
        }
    }

    private func finishStart(_ result: Result<AVAudioUnitSampler?, SamplerStartFailure>) {
        switch result {
        case let .failure(what):
            os_log(.info, log: log, "set active audio session")
            postAlert(for: what)
        case .success:
            midi.controller = keyboard
            volumeMonitor?.start()
        }
    }

    /**
     Stop audio processing. This is done prior to the app moving into the background.
     */
    func stopAudio() {
        midi.controller = nil
        volumeMonitor?.stop()
        sampler.stop()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: [])
            os_log(.info, log: log, "set audio session inactive")
        } catch let error as NSError {
            os_log(.error, log: log, "Failed session.setActive(false): %{public}s", error.localizedDescription)
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
        midi.controller = keyboard
        volumeMonitor = VolumeMonitor(muteDetector: MuteDetector(checkInterval: 1), keyboard: keyboard)
        router.activePatchManager.subscribe(self, notifier: activePatchChange)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new, playSample: playSample) = event {
            useActivePatchKind(new, playSample: playSample)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind, playSample: Bool) {
        volumeMonitor?.activePreset = activePatchKind != .none
        keyboard.releaseAllKeys()
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.sampler.loadActivePreset {
                if playSample { self.noteInjector.post(to: self.sampler) }
            }

            if case let .failure(what) = result {
                DispatchQueue.main.async { self.postAlert(for: what) }
            }
        }
    }

    private func postAlert(for what: SamplerStartFailure) {
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
