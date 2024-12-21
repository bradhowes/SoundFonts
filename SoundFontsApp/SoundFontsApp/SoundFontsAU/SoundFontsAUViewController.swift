// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os.log

public enum SoundFontsAUFailure: Error {
  case missingAudioEngine
  case unableToStart
}

/// The view controller class for the SoundFonts AUv3 app extension. Presents the same UI as the app except for the
/// keyboard component.
public final class SoundFontsAUViewController: AUViewController {
  private var log: Logger!
  private var components: Components<SoundFontsAUViewController>!
  private var audioUnit: SoundFontsAU?

  override public func viewDidLoad() {
    super.viewDidLoad()
    let identity = RandomWords.uniqueIdentifier
    log = Logging.logger("SoundFontsAUViewController[\(identity)]")
    components = Components<SoundFontsAUViewController>.make(inApp: false, identity: identity)
    components.setMainViewController(self)
    log.debug("viewDidLoad END")
  }
}

extension SoundFontsAUViewController: AUAudioUnitFactory {

  /**
   Create an audio unit to go with the view.

   - parameter componentDescription: the definition used when locating the component to create
   - returns: new SoundFontsAU instance
   */
  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    return try log.measure("createAudioUnit") {
      guard let audioEngine = components.audioEngine else {
        log.fault("missing audioEngine instance")
        throw SoundFontsAUFailure.missingAudioEngine
      }

      let audioUnit = try SoundFontsAU(
        componentDescription: componentDescription,
        audioEngine: audioEngine,
        identity: components.identity,
        activePresetManager: components.activePresetManager,
        settings: components.settings
      )

      self.audioUnit = audioUnit
      return audioUnit
    }
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
