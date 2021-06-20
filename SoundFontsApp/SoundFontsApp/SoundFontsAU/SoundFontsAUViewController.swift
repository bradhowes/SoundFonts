// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

/// The view controller class for the SoundFonts AUv3 app extension. Presents the same UI as the app except for the
/// keyboard component.
public final class SoundFontsAUViewController: AUViewController {
  private lazy var log = Logging.logger("SoundFontsAUViewController")
  private let noteInjector = NoteInjector()
  private var components: Components<SoundFontsAUViewController>!
  private var audioUnit: SoundFontsAU?

  override public func viewDidLoad() {
    os_log(.info, log: log, "viewDidLoad")
    super.viewDidLoad()
    components = Components<SoundFontsAUViewController>(inApp: false)
    components.setMainViewController(self)
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
    let audioUnit = try SoundFontsAU(
      componentDescription: componentDescription, sampler: components.sampler,
      activePresetManager: components.activePresetManager)
    os_log(.info, log: log, "created SoundFontsAU")
    self.audioUnit = audioUnit
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
    guard audioUnit != nil else { return }
    switch components.sampler.loadActivePreset() {
    case .success: break
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
