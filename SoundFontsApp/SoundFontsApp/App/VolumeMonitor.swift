// Copyright © 2020 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework
import os
import ProgressHUD

/// Monitor volume setting on device and the "silence" or "mute" switch. When there is no apparent audio
/// output, update the Keyboard and NotePlayer instances so that they can show an indication to the user.
final class VolumeMonitor {
  private lazy var log = Logging.logger("VolumeMonitor")

  private enum Reason {
    /// Volume level is at zero
    case volumeLevel
    /// There is no preset active in the synth
    case noPreset
  }

  private let keyboard: AnyKeyboard?

  private var volume: Float = 1.0 {
    didSet {
      os_log(.debug, log: log, "volume changed %f", volume)
      update()
    }
  }

  private var reason: Reason?
  private var sessionVolumeObserver: NSKeyValueObservation?

  /// Set to true if there is a valid preset installed and in use by the synth.
  public var validActivePreset = true

  /**
   Construct new monitor.

   - parameter keyboard: Keyboard instance that handle key renderings
   */
  init(keyboard: AnyKeyboard?) {
    self.keyboard = keyboard
  }
}

extension VolumeMonitor {

  /**
   Begin monitoring volume of the given AVAudioSession

   - parameter session: the AVAudioSession to monitor
   */
  func start() {
    os_log(.debug, log: log, "start")
    reason = nil
    let session = AVAudioSession.sharedInstance()
    sessionVolumeObserver = session.observe(\.outputVolume) { [weak self] session, _ in
      self?.volume = session.outputVolume
    }
    volume = session.outputVolume
  }

  /**
   Stop monitoring the output volume of an AVAudioSession
   */
  func stop() {
    os_log(.debug, log: log, "stop")
    reason = nil
    sessionVolumeObserver?.invalidate()
    sessionVolumeObserver = nil
  }
}

extension VolumeMonitor {

  /**
   Check the current volume state.
   */
  // func check() { update() }

  /**
   Show any previously-posted silence reason.
   */
  func repostNotice() { showReason() }
}

extension VolumeMonitor {

  private func update() {
    if volume < 0.01 {
      reason = .volumeLevel
    } else if !validActivePreset {
      reason = .noPreset
    } else {
      reason = .none
    }

    keyboard?.isMuted = reason != .none

    os_log(.debug, log: log, "reason: %{public}s", reason.debugDescription)
    showReason()
  }

  private func showReason() {
    switch reason {
    case .volumeLevel: ProgressHUD.banner("Volume", Formatters.strings.volumeIsZero)
    case .noPreset: ProgressHUD.banner("Preset", Formatters.strings.noPresetLoaded)
    case .none: ProgressHUD.bannerHide()
    }
  }
}
