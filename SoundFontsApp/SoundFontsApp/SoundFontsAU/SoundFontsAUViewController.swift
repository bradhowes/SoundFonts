// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

/// The view controller class for the SoundFonts AUv3 app extension. Presents the same UI as the app except for the
/// keyboard component.
public final class SoundFontsAUViewController: AUViewController {
  private lazy var log = Logging.logger("SoundFontsAUViewController")

  private var noteInjector: NoteInjector!
  private var components: Components<SoundFontsAUViewController>! = nil
  private var audioUnit: SoundFontsAU?

  deinit {
    os_log(.info, log: log, "deinit - %{public}s", String.pointer(self))
  }

  override public func loadView() {
    os_log(.info, log: log, "loadView - BEGIN")
    components = Components<SoundFontsAUViewController>(inApp: false)
    noteInjector = .init(settings: components.settings)
    os_log(.info, log: log, "super.loadView")
    super.loadView()
    os_log(.info, log: log, "loadView - END")
  }

  override public func viewDidLoad() {
    os_log(.info, log: log, "viewDidLoad - BEGIN: %{public}s", String.pointer(self))
    super.viewDidLoad()
    components.setMainViewController(self)
    os_log(.info, log: log, "viewDidLoad - END")
  }
}

extension SoundFontsAUViewController: AUAudioUnitFactory {

  /**
   Create an audio unit to go with the view.

   - parameter componentDescription: the definition used when locating the component to create
   - returns: new SoundFontsAU instance
   */
  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    os_log(.info, log: log, "createAudioUnit")
    let audioUnit = try SoundFontsAU(componentDescription: componentDescription,
                                     sampler: components.sampler,
                                     activePresetManager: components.activePresetManager,
                                     identity: components.settings.identity?.index ?? -1)
    self.audioUnit = audioUnit
    os_log(.info, log: log, "createAudioUnit - END: %{public}s", String.pointer(audioUnit))
    return audioUnit
  }
}

// MARK: - Controller Configuration

extension SoundFontsAUViewController: ControllerConfiguration {

  /**
   Establish connections with other managers / controllers.

   - parameter context: the RunContext that holds all of the registered managers / controllers
   */
  public func establishConnections(_ router: ComponentContainer) {
    router.activePresetManager.subscribe(self, notifier: activePresetChange)
  }

  private func activePresetChange(_ event: ActivePresetEvent) {
    if case let .active(old: _, new: _, playSample: playSample) = event {
      os_log(.info, log: log, "activePresetChange - playSample: %d", playSample)
      useActivePresetKind(playSample: playSample)
    }
  }

  private func useActivePresetKind(playSample: Bool) {
    os_log(.info, log: log, "useActivePresetKind - playSample: %d", playSample)
    guard let audioUnit = self.audioUnit else { return }
    switch components.sampler.loadActivePreset() {
    case .success:
      self.noteInjector.post(to: audioUnit)
    case .failure(let reason):
      switch reason {
      case .noSampler: os_log(.info, log: log, "no sampler")
      case .sessionActivating(let err):
        os_log(
          .info, log: log, "failed to activate session: %{public}s",
          err.localizedDescription)
      case .engineStarting(let err):
        os_log(
          .info, log: log, "failed to start engine: %{public}s",
          err.localizedDescription)
      case .presetLoading(let err):
        os_log(
          .info, log: log, "failed to load preset: %{public}s",
          err.localizedDescription)
      }
    }
  }
}
