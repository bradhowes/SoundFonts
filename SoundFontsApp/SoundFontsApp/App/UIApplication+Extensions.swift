// Copyright © 2019 Brad Howes. All rights reserved.

import SoundFontsFramework
import UIKit
import os

extension UIApplication {
  private var log: Logger { Logging.logger("UIApplication") }

  /// Obtain the AppDelegate instance for the application
  var appDelegate: AppDelegate? { self.delegate as? AppDelegate }

  func startAudio() {
    log.debug("startAudio")
    isIdleTimerDisabled = true
    appDelegate?.startAudioSession()
  }

  func stopAudio(quitting: Bool) {
    log.debug("stopAudio - \(quitting)")
    appDelegate?.stopAudioSession(quitting: quitting)
  }
}
