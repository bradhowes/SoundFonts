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
  private let identity = RandomWords.uniqueIdentifier
  private let log: Logger
  private let components: Components<SoundFontsAUViewController>
  private var audioUnit: SoundFontsAU?

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.log = Logging.logger("SoundFontsAUViewController[\(identity)]")
    self.components = Components<SoundFontsAUViewController>.make(inApp: false, identity: identity)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder: NSCoder) {
    self.log = Logging.logger("SoundFontsAUViewController[\(identity)]")
    self.components = Components<SoundFontsAUViewController>.make(inApp: false, identity: identity)
    super.init(coder: coder)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
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
