// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

/// The view controller class for the SoundFonts AUv3 app extension. Presents the same UI as the app except for the
/// keyboard component.
public final class SoundFontsAUViewController: AUViewController {
  private lazy var log = Logging.logger("SoundFontsAUViewController")
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
    let audioUnit = try SoundFontsAU(componentDescription: componentDescription,
                                     activePresetManager: components.activePresetManager,
                                     settings: components.settings)
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
  public func establishConnections(_ router: ComponentContainer) {}
}
