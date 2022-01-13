// Copyright © 2018 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework
import UIKit
import os

/// Top-level view controller for the application. It contains the Sampler which will emit sounds based on what keys are
/// touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
/// to the background or stops being active.
final class MainViewController: UIViewController {
  private lazy var log = Logging.logger("MainViewController")

  private weak var router: ComponentContainer?
  private var midiController: MIDIController?
  private var activePresetManager: ActivePresetManager!
  private var keyboard: Keyboard!
  private var sampler: Sampler?
  private var infoBar: InfoBar!
  private var settings: Settings!
  fileprivate var noteInjector: NoteInjector!

  private var startRequested = false
  private var volumeMonitor: VolumeMonitor?
  private var observers = [NSObjectProtocol]()


  /// Disable system gestures near screen edges so that touches on the keyboard are always seen by the application.
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    return [.left, .right, .bottom]
  }

  /// If true, do not show the tutorial pages for the first time the application starts. This is used by the UI tests.
  var skipTutorial = false

  override func viewDidLoad() {
    super.viewDidLoad()
    UIApplication.shared.appDelegate.setMainViewController(self)
    setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    observers.append(NotificationCenter.default.addObserver(forName: .showTutorial, object: nil,
                                                            queue: nil) { [weak self] _ in
      self?.showTutorial()
    })

    observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                                            object: nil, queue: nil) { [weak self] _ in
      self?.recreateSampler()
    })
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !skipTutorial && !settings.showedTutorial {
      showTutorial()
      settings.showedTutorial = true
    }
  }

  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    coordinator.animate(
      alongsideTransition: { _ in
        InfoHUD.clear()
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
  func showChanges() {
    let currentVersion = Bundle.main.releaseVersionNumber
    if settings.showedChanges != currentVersion {
      let changes = ChangesCompiler.compile(since: settings.showedChanges)
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
    if let viewController = TutorialViewController.instantiate() {
      present(viewController, animated: true, completion: nil)
    }
  }

  /**
   Start audio processing. This is done as the app is brought into the foreground.
   */
  func startAudio() {
    os_log(.info, log: log, "startAudio")
    startRequested = true
    guard let sampler = self.sampler else { return }
    DispatchQueue.global(qos: .userInitiated).async { self.startAudioBackground(sampler) }
  }

  @objc func handleRouteChange(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }

    // Switch over the route change reason.
    switch reason {

    case .newDeviceAvailable: // New device found.
      let session = AVAudioSession.sharedInstance()
      dump(route: session.currentRoute)

    case .oldDeviceUnavailable: // Old device removed.
      let session = AVAudioSession.sharedInstance()
      if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
        dump(route: previousRoute)
        dump(route: session.currentRoute)
      }

    default:
      os_log(.info, log: log, "AVAudioSession.unknown reason - %d", reason.rawValue)
    }
  }

  /**
   Stop audio processing. This is done prior to the app moving into the background.
   */
  func stopAudio() {
    startRequested = false
    guard sampler != nil else { return }

    MIDI.sharedInstance.receiver = nil
    volumeMonitor?.stop()
    sampler?.stop()

    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(false, options: [])
      os_log(.info, log: log, "set audio session inactive")
    } catch let error as NSError {
      os_log(
        .error, log: log, "Failed session.setActive(false): %{public}s", error.localizedDescription)
    }
  }
}

// MARK: - Controller Configuration

extension MainViewController: ControllerConfiguration {

  private func startAudioBackground(_ sampler: Sampler) {
    let sampleRate: Double = 44100.0
    let bufferSize: Int = 512
    let session = AVAudioSession.sharedInstance()

    setupAudioSessionNotifications()

    do {
      do {
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
      } catch let error as NSError {
        os_log(
          .error, log: log, "Failed to set the audio session category and mode: %{public}s",
          error.localizedDescription)
      }

      os_log(.info, log: log, "sampleRate: %f", AVAudioSession.sharedInstance().sampleRate)
      os_log(.info, log: log, "preferredSampleRate: %f", AVAudioSession.sharedInstance().sampleRate)

      do {
        try session.setPreferredSampleRate(sampleRate)
      } catch let error as NSError {
        os_log(
          .error, log: log, "Failed to set the preferred sample rate to %f: %{public}s",
          sampleRate, error.localizedDescription)
      }

      do {
        try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
      } catch let error as NSError {
        os_log(
          .error, log: log, "Failed to set the preferred buffer size to %d: %{public}s",
          bufferSize, error.localizedDescription)
      }

      os_log(.info, log: log, "setting active audio session")
      try session.setActive(true, options: [])

      dump(route: session.currentRoute)

      os_log(.info, log: log, "starting sampler")
      let result = sampler.start()
      DispatchQueue.main.async { self.finishStart(result) }
    } catch let error as NSError {
      let result: SamplerStartFailure = .sessionActivating(error: error)
      os_log(
        .error, log: log, "Failed session.setActive(true): %{public}s", error.localizedDescription)
      DispatchQueue.main.async { self.finishStart(.failure(result)) }
    }
  }

  /**
   Establish connections with other managers / controllers.

   - parameter router: the ComponentContainer that holds all of the registered managers / controllers
   */
  func establishConnections(_ router: ComponentContainer) {
    os_log(.info, log: log, "establishConnections BEGIN")
    self.router = router

    infoBar = router.infoBar
    keyboard = router.keyboard
    activePresetManager = router.activePresetManager
    settings = router.settings
    noteInjector = .init(settings: settings)

    #if !targetEnvironment(macCatalyst)
    volumeMonitor = VolumeMonitor(keyboard: router.keyboard)
    #endif

    router.activePresetManager.subscribe(self, notifier: activePresetChanged)

    let preset: ActivePresetKind = {
      let lastActivePreset = settings.lastActivePreset
      if lastActivePreset != .none { return lastActivePreset }
      if let defaultPreset = router.soundFonts.defaultPreset { return .preset(soundFontAndPreset: defaultPreset) }
      return .none
    }()

    activePresetManager.restoreActive(preset)

    router.subscribe(self, notifier: routerChanged)
    if let sampler = router.sampler {
      setSampler(sampler)
    }
    
    os_log(.info, log: log, "establishConnections END")
  }

  private func startMIDI() {
    guard let sampler = self.sampler else { return }
    os_log(.error, log: log, "starting MIDI for sampler")
    midiController = MIDIController(sampler: sampler, keyboard: keyboard, settings: settings)
    MIDI.sharedInstance.receiver = midiController
  }

  private func routerChanged(_ event: ComponentContainerEvent) {
    os_log(.info, log: log, "routerChanged: %{public}s", event.description)
    switch event {
    case .samplerAvailable(let sampler): setSampler(sampler)
    case .reverbAvailable: break
    case .delayAvailable: break
    case .chorusAvailable: break
    }
  }

  private func setSampler(_ sampler: Sampler) {
    self.sampler = sampler
    if startRequested {
      DispatchQueue.global(qos: .userInitiated).async { self.startAudioBackground(sampler) }
    }
  }

  private func activePresetChanged(_ event: ActivePresetEvent) {
    if case let .change(old: _, new: new, playSample: playSample) = event {
      useActivePresetKind(new, playSample: playSample)
    }
  }

  private func useActivePresetKind(_ activePresetKind: ActivePresetKind, playSample: Bool) {
    volumeMonitor?.activePreset = activePresetKind != .none
    midiController?.allNotesOff()
    guard let sampler = self.sampler else { return }

    DispatchQueue.global(qos: .userInitiated).async {
      let result = sampler.loadActivePreset {
        if playSample { self.noteInjector.post(to: sampler) }
      }

      if case let .failure(what) = result, what != .noSampler {
        DispatchQueue.main.async { self.postAlert(for: what) }
      }
    }
  }

  private func finishStart(_ result: Sampler.StartResult) {
    switch result {
    case let .failure(what):
      os_log(.info, log: log, "set active audio session")
      postAlert(for: what)
    case .success:
      volumeMonitor?.start()
      startMIDI()
    }
  }

  private func recreateSampler() {
    os_log(.error, log: log, "recreating audio components due to media services reset")
    self.stopAudio()
    self.sampler = nil
    router?.createAudioComponents()
    self.startAudio()
  }

  private func postAlert(for what: SamplerStartFailure) {
    NotificationCenter.default.post(Notification(name: .samplerStartFailure, object: what))
  }

  private func setupAudioSessionNotifications() {
    NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange),
                                           name: AVAudioSession.routeChangeNotification, object: nil)
  }

  private func dump(route: AVAudioSessionRouteDescription) {
    for input in route.inputs {
      os_log(.info, log: log, "AVAudioSession input - %{public}s", input.portName)
    }
    for output in route.outputs {
      os_log(.info, log: log, "AVAudioSession output - %{public}s", output.portName)
    }
  }
}
