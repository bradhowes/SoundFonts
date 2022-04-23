// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os.log

public enum SoundFontsAUFailure: Error {
  case missingSynth
  case unableToStart
}

/// The view controller class for the SoundFonts AUv3 app extension. Presents the same UI as the app except for the
/// keyboard component.
public final class SoundFontsAUViewController: AUViewController {
  private lazy var log = Logging.logger("SoundFontsAUViewController")
  private var components: Components<SoundFontsAUViewController>!
  private var audioUnit: SoundFontsAU?

  override public func viewDidLoad() {
    os_log(.debug, log: log, "viewDidLoad BEGIN - %{public}s", String.pointer(self))
    super.viewDidLoad()
    components = Components<SoundFontsAUViewController>(inApp: false)
    components.setMainViewController(self)
    os_log(.debug, log: log, "viewDidLoad END")
  }
}

extension SoundFontsAUViewController: AUAudioUnitFactory {

  /**
   Create an audio unit to go with the view.

   - parameter componentDescription: the definition used when locating the component to create
   - returns: new SoundFontsAU instance
   */
  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    os_log(.debug, log: log, "createAudioUnit BEGIN - %{public}s", String.pointer(self))

    guard let synth = components.synth else {
      os_log(.fault, log: log, "missing synth instance")
      throw SoundFontsAUFailure.missingSynth
    }

    let audioUnit = try SoundFontsAU(componentDescription: componentDescription,
                                     synth: synth,
                                     identity: components.identity,
                                     activePresetManager: components.activePresetManager,
                                     settings: components.settings)
    self.audioUnit = audioUnit

    os_log(.debug, log: log, "createAudioUnit END - %{public}s", String.pointer(audioUnit))
    return audioUnit
  }
}

// MARK: - Controller Configuration

extension SoundFontsAUViewController: ControllerConfiguration {

  /**
   Establish connections with other managers / controllers.

   - parameter context: the RunContext that holds all of the registered managers / controllers
   */
  public func establishConnections(_ router: ComponentContainer) {}
}
