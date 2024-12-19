// Copyright © 2018 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework
import MorkAndMIDI
import UIKit
import os
import ProgressHUD

/**
 Top-level view controller for the application. It contains the Synth which will emit sounds based on what keys are
 touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
 to the background or stops being active.
 */
final class MainViewController: UIViewController {
  private lazy var log: Logger = Logging.logger("MainViewController")

  private var activePresetManager: ActivePresetManager!
  private var audioEngine: AudioEngine?
  private var settings: Settings!
  private var askForReview: AskForReview?

  private var startRequested = false
  private var volumeMonitor: VolumeMonitor?
  private var observers = [NSObjectProtocol]()
#if TEST_MEDIA_SERVICES_RESTART // see Development.xcconfig
  private var resetTimers = [Timer]()
#endif

  /// Disable system gestures near screen edges so that touches on the keyboard are always seen by the application.
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    return [.left, .right, .bottom]
  }

  /// If true, do not show the tutorial pages for the first time the application starts. This is used by the UI tests.
  /// It is set by `AppDelegate` to true when "-ui_testing" is present on the command line.
  var skipTutorial = false
  /// If true, always show the "changes" screen
  var alwaysShowChanges = false

  override func viewDidLoad() {
    super.viewDidLoad()
    UIApplication.shared.appDelegate.setMainViewController(self)
    setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    observers.append(NotificationCenter.default.addObserver(forName: .showChanges, object: nil,
                                                            queue: nil) { [weak self] _ in
      self?.showChanges(true)
    })
    observers.append(NotificationCenter.default.addObserver(forName: .showTutorial, object: nil,
                                                            queue: nil) { [weak self] _ in
      self?.showTutorial()
    })
    observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                                            object: nil, queue: nil) { [weak self] _ in
      self?.recreateSynth()
    })
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if !skipTutorial {
      if !settings.showedTutorial {
        showTutorial()
        settings.showedTutorial = true
      } else {
        showChanges()
      }
    }

    askForReview?.windowScene = view.window?.windowScene

#if TEST_MEDIA_SERVICES_RESTART // See Development.xcconfig
    resetTimers.append(Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
      NotificationCenter.default.post(name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    })
#endif
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    askForReview?.windowScene = nil
  }

  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    coordinator.animate(
      alongsideTransition: { _ in
        ProgressHUD.bannerHide()
      },
      completion: { _ in
        self.volumeMonitor?.repostNotice()
      })
  }
}

extension MainViewController {
  
  /**
   Show the changes screen if there are changes to be shown.
   */
  func showChanges(_ force: Bool = false) {
    let currentVersion = alwaysShowChanges ? "" : Bundle.main.releaseVersionNumber
    
    if settings.showedChanges != currentVersion || alwaysShowChanges || force {
      let changes = ChangesCompiler.compile()
      settings.showedChanges = currentVersion
      if let viewController = TutorialViewController.instantiateChanges(changes) {
        present(viewController, animated: true, completion: nil)
      }
    }
  }

  /**
   Show the tutorial screens.
   */
  func showTutorial() {
    log.debug("showTuorial")
    if let viewController = TutorialViewController.instantiate() {
      present(viewController, animated: true, completion: nil)
    }
  }

  /**
   Start audio processing. This is done as the app is brought into the foreground. Note that most of the processing is
   moved to a background thread so as not to block the main thread when app is launching.
   */
  func startAudioSession() {
    log.debug("startAudioSession BEGIN")

    guard let audioEngine = self.audioEngine else {
      // The synth has not loaded yet, so we postpone until it is.
      log.debug("startAudioSession END - no synth")
      startRequested = true
      return
    }

    DispatchQueue.global(qos: .userInitiated).async { self.startAudioSessionInBackground(audioEngine) }
    log.debug("startAudioSession END")
  }

  @objc func handleRouteChangeInBackground(notification: Notification) {
    log.debug("handleRouteChangeInBackground BEGIN")
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
    else {
      log.debug("handleRouteChangeInBackground END - nothing to see")
      return
    }

    // Switch over the route change reason.
    switch reason {

    case .newDeviceAvailable: // New device found.
      log.debug("handleRouteChangeInBackground - new device available")
      let session = AVAudioSession.sharedInstance()
      dump(route: session.currentRoute)

    case .oldDeviceUnavailable: // Old device removed.
      log.debug("handleRouteChangeInBackground - old device unavailable")
      let session = AVAudioSession.sharedInstance()
      if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
        dump(route: previousRoute)
        dump(route: session.currentRoute)
      }

    default:
      log.debug("handleRouteChangeInBackground - AVAudioSession.unknown reason - \(reason.rawValue)")
    }
    log.debug("handleRouteChangeInBackground END")
  }

  /**
   Stop audio processing. This is only done if background running is disabled and then just before the app moves into
   the background.
   */
  func stopAudio() {
    log.debug("stopAudio BEGIN")

    guard audioEngine != nil else {
      log.debug("stopAudio END - no synth")
      return
    }

    volumeMonitor?.stop()
    audioEngine?.stop()

    let session = AVAudioSession.sharedInstance()
    do {
      log.debug("stopAudio - setting AudioSession to inactive")
      try session.setActive(false, options: [])
      log.debug("stopAudio - done")
    } catch let error as NSError {
      log.error("stopAudio - Failed session.setActive(false): \(error.localizedDescription)")
    }

    log.debug("stopAudio END")
  }
}

// MARK: - Controller Configuration

extension MainViewController: ControllerConfiguration {

  private func startAudioSessionInBackground(_ audioEngine: AudioEngine) {
    log.debug("startAudioSessionInBackground BEGIN")

    let sampleRate: Double = 44100.0
    let bufferSize: Int = 64
    let session = AVAudioSession.sharedInstance()

    setupAudioSessionNotificationsInBackground()

    do {
      log.debug("startAudioSessionInBackground - setting AudioSession category")
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      log.debug("startAudioSessionInBackground - done")
    } catch let error as NSError {
      log.error(
        "startAudioSessionInBackground - failed to set the audio session category and mode: \(error.localizedDescription)"
      )
    }

    log.debug("startAudioSessionInBackground - sampleRate: \(AVAudioSession.sharedInstance().sampleRate)")
    log.debug("startAudioSessionInBackground - preferredSampleRate: \(AVAudioSession.sharedInstance().sampleRate)")

    do {
      log.debug("startAudioSessionInBackground - setting sample rate")
      try session.setPreferredSampleRate(sampleRate)
      log.debug("startAudioSessionInBackground - done")
    } catch let error as NSError {
      log.error("startAudioSessionInBackground - failed to set the preferred sample rate to \(sampleRate) - \(error.localizedDescription)")
    }

    do {
      log.debug("startAudioSessionInBackground - setting IO buffer duration")
      try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
      log.debug("startAudioSessionInBackground - done")
    } catch let error as NSError {
      log.error("startAudioSessionInBackground - failed to set the preferred buffer size to \(bufferSize) - \(error.localizedDescription)")
    }

    do {
      log.debug("startAudioSessionInBackground - setting active audio session")
      try session.setActive(true, options: [])
      log.debug("startAudioSessionInBackground - done")
    } catch {
      log.error("startAudioSessionInBackground - failed to set active - \(error.localizedDescription)")
    }

    dump(route: session.currentRoute)

    log.debug("startAudioSessionInBackground - starting synth")
    let result = audioEngine.start()

    DispatchQueue.main.async { self.finishStart(result) }
    log.debug("startAudioSessionInBackground END")
  }

  /**
   Establish connections with other managers / controllers.

   - parameter router: the ComponentContainer that holds all of the registered managers / controllers
   */
  func establishConnections(_ router: ComponentContainer) {
    log.debug("establishConnections BEGIN")

    activePresetManager = router.activePresetManager
    settings = router.settings
    askForReview = router.askForReview
    
#if !targetEnvironment(macCatalyst)
    volumeMonitor = VolumeMonitor(keyboard: router.keyboard)
#endif

    router.infoBar.addEventClosure(.panic) { [weak self] _ in
      guard let self = self else { return }
      router.infoBar.setStatusText("All notes off")
      self.audioEngine?.stopAllNotes()
    }

    guard let keyboard = router.keyboard else {
      fatalError("main app needs a keyboard to play")
    }

    if let audioEngine = router.audioEngine {
      activePresetManager.runOnNotifyQueue {
        audioEngine.attachKeyboard(keyboard)
        self.setAudioEngineInBackground(audioEngine)
      }
    } else {
      router.subscribe(self) { [weak self] event in
        guard let self = self else { return }
        switch event {
        case .audioEngineAvailable(let audioEngine):
          audioEngine.attachKeyboard(keyboard)
          self.setAudioEngineInBackground(audioEngine)
        }
      }
    }

    activePresetManager.restoreActive(settings.lastActivePreset)
    log.debug("establishConnections END")
  }

  private func setAudioEngineInBackground(_ audioEngine: AudioEngine) {
    log.debug("setSynthInBackground BEGIN")
    guard self.audioEngine == nil else { return }

    self.audioEngine = audioEngine

    // If we were started but did not have the synth available, now we can continue starting the audio session.
    if startRequested {
      startRequested = false
      self.startAudioSessionInBackground(audioEngine)
    }

    log.debug("setSynthInBackground END")
  }

  private func finishStart(_ result: AudioEngine.StartResult) {
    log.debug("finishStart BEGIN - \(result.description)")

    switch result {
    case let .failure(what):
      log.debug("finishStart - failed to start audio session")
      postAlertInBackground(for: what)
    case .success:
      log.debug("finishStart - starting volumeMonitor and MIDI")
      volumeMonitor?.start()
    }
    log.error("finishStart - END")
  }

  private func recreateSynth() {
    log.error("recreateSynth - BEGIN")
    stopAudio()
    startAudioSession()
    log.error("recreateSynth - END")
  }

  private func postAlertInBackground(for what: SynthStartFailure) {
    DispatchQueue.main.async { NotificationCenter.default.post(Notification(name: .synthStartFailure, object: what)) }
  }

  private func setupAudioSessionNotificationsInBackground() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChangeInBackground),
                                           name: AVAudioSession.routeChangeNotification, object: nil)
  }

  private func dump(route: AVAudioSessionRouteDescription) {
    for input in route.inputs {
      log.debug("AVAudioSession input - \(input.portName)")
    }
    for output in route.outputs {
      log.debug("AVAudioSession output - \(output.portName)")
    }
  }
}
