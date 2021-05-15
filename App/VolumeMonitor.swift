// Copyright © 2020 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework
import os

/**
 Monitor volume setting on device and the "silence" or "mute" switch. When there is no apparent audio
 output, update the Keyboard and NotePlayer instances so that they can show an indication to the user.
 */
final class VolumeMonitor {
    private let log = Logging.logger("VolMon")

    private enum Reason {
        /// Volume level is at zero
        case volumeLevel
        /// Mute switch is enabled
        case muteSwitch
        /// There is no preset active in the sampler
        case noPreset
        /// Another app is playing audio
        case otherAudio
    }

    private let muteDetector: MuteDetector?
    private let keyboard: Keyboard?

    private var volume: Float = 1.0 {
        didSet {
            os_log(.info, log: log, "volume changed %f", volume)
            update()
        }
    }

    private var muted = false {
        didSet {
            guard oldValue != muted else { return }
            os_log(.info, log: log, "muted flag changed %d", muted)
            update()
        }
    }

    private var reason: Reason?
    private var sessionVolumeObserver: NSKeyValueObservation?

    /// Set to true if there is a valid preset installed and in use by the sampler.
    public var activePreset = true

    /**
     Construct new monitor.

     - parameter keyboard: Keyboard instance that handle key renderings
     - parameter notePlayer: NotePlayer instance that handles note playing
     */
    init(muteDetector: MuteDetector?, keyboard: Keyboard?) {
        self.muteDetector = muteDetector
        self.keyboard = keyboard
    }
}

extension VolumeMonitor {

    /**
     Begin monitoring volume of the given AVAudioSession

     - parameter session: the AVAudioSession to monitor
     */
    func start() {
        os_log(.info, log: log, "start")
        reason = nil

        muteDetector?.notifier = {self.muted = $0}
        muteDetector?.start()

        let session = AVAudioSession.sharedInstance()
        sessionVolumeObserver = session.observe(\.outputVolume) { [weak self] session, _ in
            self?.volume = session.outputVolume
        }
    }

    /**
     Stop monitoring the output volume of an AVAudioSession
     */
    func stop() {
        os_log(.info, log: log, "stop")
        reason = nil

        muteDetector?.notifier = nil
        muteDetector?.stop()

        sessionVolumeObserver?.invalidate()
        sessionVolumeObserver = nil
    }
}

extension VolumeMonitor {

    /**
     Check the current volume state.
     */
    func check() { update() }

    /**
     Show any previously-posted silence reason.
     */
    func repostNotice() { showReason() }
}

extension VolumeMonitor {

    private func update() {
        if volume < 0.01 {
            reason = .volumeLevel
        }
        else if muted {
            if AVAudioSession.sharedInstance().isOtherAudioPlaying ||
                AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint {
                reason = .otherAudio
            }
            else {
                reason = .muteSwitch
            }
        }
        else if !activePreset {
            reason = .noPreset
        }
        else {
            reason = .none
        }

        keyboard?.isMuted = reason != .none

        os_log(.info, log: log, "reason: %{public}s", reason.debugDescription)
        showReason()
    }

    private func showReason() {
        switch reason {
        case .volumeLevel: InfoHUD.show(text: Formatters.strings.volumeIsZero)
        case .muteSwitch: InfoHUD.show(text: Formatters.strings.silentModeActive)
        case .noPreset: InfoHUD.show(text: Formatters.strings.noPresetLoaded)
        case .otherAudio: InfoHUD.show(text: Formatters.strings.otherAppAudio)
        case .none: InfoHUD.clear()
        }
    }
}
