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

    enum Reason {
        case volumeLevel
        case muteSwitch
        case noPatch
        case otherAudio
    }

    private let muteDetector: MuteDetector?
    private let keyboard: Keyboard
    private let notePlayer: NotePlayer
    private let sampler: Sampler

    public var checkForPreset = false

    private var volume: Float = 0.0 {
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

    /**
     Construct new monitor.

     - parameter keyboard: Keyboard instance that handle key renderings
     - parameter notePlayer: NotePlayer instance that handles note playing
     */
    init(muteDetector: MuteDetector?, keyboard: Keyboard, notePlayer: NotePlayer, sampler: Sampler) {
        self.muteDetector = muteDetector
        self.keyboard = keyboard
        self.notePlayer = notePlayer
        self.sampler = sampler
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
        sessionVolumeObserver = session.observe(\.outputVolume, options: [.initial, .new]) { session, _ in self.volume = session.outputVolume }
        update()
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
     Check the current volume sttae.
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
            if AVAudioSession.sharedInstance().isOtherAudioPlaying {
                reason = .otherAudio
            }
            else {
                reason = .muteSwitch
            }
        }
        else if checkForPreset && !sampler.hasPatch {
            reason = .noPatch
        }
        else {
            reason = .none
        }

        keyboard.isMuted = reason != .none
        notePlayer.isMuted = reason != .none

        os_log(.info, log: log, "reason: %s", reason.debugDescription)
        showReason()
    }

    private func showReason() {
        switch reason {
        case .volumeLevel: InfoHUD.show(text: "Volume set to 0")
        case .muteSwitch: InfoHUD.show(text: "Silent Mode is active")
        case .noPatch: InfoHUD.show(text: "No patch is currently selected.")
        case .otherAudio: InfoHUD.show(text: "Another app is controlling audio.")
        case .none: InfoHUD.clear()
        }
    }
}
