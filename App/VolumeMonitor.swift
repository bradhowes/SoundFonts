// Copyright © 2020 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework

/**
 Monitor volume setting on device and the "silence" or "mute" switch. When there is no apparent audio
 output, update the Keyboard and NotePlayer instances so that they can show an indication to the user.
 */
final class VolumeMonitor {

    enum Reason {
        case volumeLevel
        case muteSwitch
        case noPatch
        case otherAudio
    }

    private let keyboard: Keyboard
    private let notePlayer: NotePlayer
    private let sampler: Sampler

    private var volume: Float = 0.0 { didSet { update() } }
    private var muted = false { didSet { update() } }
    private var reason: Reason?

    private var sessionVolumeObserver: NSKeyValueObservation?

    /**
     Construct new monitor.

     - parameter keyboard: Keyboard instance that handle key renderings
     - parameter notePlayer: NotePlayer instance that handles note playing
     */
    init(keyboard: Keyboard, notePlayer: NotePlayer, sampler: Sampler) {
        self.keyboard = keyboard
        self.notePlayer = notePlayer
        self.sampler = sampler
    }

    /**
     Begin monitoring volume of the given AVAudioSession

     - parameter session: the AVAudioSession to monitor
     */
    func start() {
        reason = nil
        Mute.shared.notify = {muted in self.muted = muted }
        Mute.shared.isPaused = false
        let session = AVAudioSession.sharedInstance()
        sessionVolumeObserver = session.observe(\.outputVolume, options: [.initial, .new]) { session, _ in
            self.volume = session.outputVolume
        }
        update()
    }

    /**
     Stop monitoring the output volume of an AVAudioSession
     */
    func stop() {
        guard !Mute.shared.isPaused else { return }
        reason = nil
        Mute.shared.notify = nil
        Mute.shared.isPaused = true
        sessionVolumeObserver?.invalidate()
        sessionVolumeObserver = nil
    }

    func update() {
        let pastReason = reason
        if AVAudioSession.sharedInstance().isOtherAudioPlaying {
            reason = .otherAudio
        }
        else if volume < 0.01 {
            reason = .volumeLevel
        }
        else if muted {
            reason = .muteSwitch
        }
        else if !sampler.hasPatch {
            reason = .noPatch
        }
        else {
            reason = .none
        }

        keyboard.isMuted = reason != .none
        notePlayer.isMuted = reason != .none

        if pastReason == .none {
            switch reason {
            case .volumeLevel: InfoHUD.show(text: "Volume set to 0")
            case .muteSwitch: InfoHUD.show(text: "Silent Mode is active")
            case .noPatch: InfoHUD.show(text: "No patch is currently selected.")
            case .otherAudio: InfoHUD.show(text: "Another app is controlling audio.")
            case .none: InfoHUD.clear()
            }
        }
    }

    func repostNotice() {
        if reason != .none {
            reason = .none
            update()
        }
    }
}
