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
    private lazy var log = Logging.logger("MainViewController")

    private var midiController: MIDIController?
    private var activePatchManager: ActivePatchManager!
    private var keyboard: Keyboard!
    private var sampler: Sampler?
    private var infoBar: InfoBar!
    private var startRequested = false
    private var volumeMonitor: VolumeMonitor?
    private let midi = MIDI()

    fileprivate var noteInjector = NoteInjector()

    /// Disable system gestures near screen edges so that touches on the keyboard are always seen by the application.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { return [.left, .right, .bottom] }

    /// If true, do not show the tutorial pages for the first time the application starts. This is used by the UI tests.
    var skipTutorial = false

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.appDelegate.setMainViewController(self)
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !skipTutorial else { return }

        // Settings.instance.showedChanges = ""
        // Settings.instance.showedTutorial = false
        
        let currentVersion = Bundle.main.releaseVersionNumber
        if !Settings.instance.showedTutorial {
            Settings.instance.showedTutorial = true
            Settings.instance.showedChanges = currentVersion
            if let viewController = TutorialViewController.instantiate() {
                present(viewController, animated: true, completion: nil)
            }
        }
        else if Settings.instance.showedChanges != currentVersion {

            // For speed of launch this should be done on separate thread
            let changes = ChangesCompiler.compile(since: Settings.instance.showedChanges)

            Settings.instance.showedChanges = currentVersion
            if let viewController = TutorialViewController.instantiateChanges(changes) {
                present(viewController, animated: true, completion: nil)
            }
        }
    }

    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            InfoHUD.clear()
        }, completion: { _ in
            self.volumeMonitor?.repostNotice()
        })
    }
}

extension MainViewController {

    /**
     Start audio processing. This is done as the app is brought into the foreground.
     */
    func startAudio() {
        startRequested = true
        guard let sampler = self.sampler else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.startAudioBackground(sampler) }
    }

    private func startAudioBackground(_ sampler: Sampler) {
        let sampleRate: Double = 44100.0
        let bufferSize: Int = 512
        let session = AVAudioSession.sharedInstance()
        do {
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            } catch let error as NSError {
                os_log(.error, log: log, "Failed to set the audio session category and mode: %{public}s",
                       error.localizedDescription)
            }

            do {
                try session.setPreferredSampleRate(sampleRate)
            } catch let error as NSError {
                os_log(.error, log: log, "Failed to set the preferred sample rate to %f: %{public}s",
                       sampleRate, error.localizedDescription)
            }

            do {
                try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
            } catch let error as NSError {
                os_log(.error, log: log, "Failed to set the preferred buffer size to %d: %{public}s",
                       bufferSize, error.localizedDescription)
            }

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

    private func finishStart(_ result: Sampler.StartResult) {
        switch result {
        case let .failure(what):
            os_log(.info, log: log, "set active audio session")
            postAlert(for: what)
        case .success:
            midi.receiver = midiController
            volumeMonitor?.start()
        }
    }

    /**
     Stop audio processing. This is done prior to the app moving into the background.
     */
    func stopAudio() {
        startRequested = false
        guard sampler != nil else { return }

        midi.receiver = nil
        volumeMonitor?.stop()
        sampler?.stop()

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

     - parameter router: the ComponentContainer that holds all of the registered managers / controllers
     */
    func establishConnections(_ router: ComponentContainer) {
        router.subscribe(self, notifier: routerChange)

        infoBar = router.infoBar
        keyboard = router.keyboard
        activePatchManager = router.activePatchManager

        #if !targetEnvironment(macCatalyst)
        volumeMonitor = VolumeMonitor(keyboard: router.keyboard)
        #endif

        router.activePatchManager.subscribe(self, notifier: activePatchChange)
    }

    private func routerChange(_ event: ComponentContainerEvent) {
        switch event {
        case .samplerAvailable(let sampler):
            self.sampler = sampler
            midiController = MIDIController(sampler: sampler, keyboard: keyboard)
            midi.receiver = midiController
            if startRequested {
                DispatchQueue.global(qos: .userInitiated).async { self.startAudioBackground(sampler) }

            }
        case .reverbAvailable: break
        case .delayAvailable: break
        }
    }
    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new, playSample: playSample) = event {
            useActivePatchKind(new, playSample: playSample)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind, playSample: Bool) {
        volumeMonitor?.activePreset = activePatchKind != .none
        midiController?.releaseAllKeys()
        guard let sampler = self.sampler else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = sampler.loadActivePreset {
                if playSample { self.noteInjector.post(to: sampler) }
            }

            if case let .failure(what) = result {
                DispatchQueue.main.async { self.postAlert(for: what) }
            }
        }
    }

    private func postAlert(for what: SamplerStartFailure) {
        NotificationCenter.default.post(Notification(name: .samplerStartFailure, object: what))
    }
}
