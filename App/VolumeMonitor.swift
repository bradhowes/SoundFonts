// Copyright © 2020 Brad Howes. All rights reserved.

import AVKit
import SoundFontsFramework

/**
 Monitor volume setting on device and the "silence" or "mute" switch. When there is no apparent audio
 output, update the Keyboard and NotePlayer instances so that they can show an indication to the user.
 */
final class VolumeMonitor {
    private let keyboard: Keyboard
    private let notePlayer: NotePlayer
    private let sampler: Sampler

    private var volume: Float = 0.0 { didSet { update() } }
    private var muted = false { didSet { update() } }
    private var isSilenced: Bool { !sampler.hasPatch || volume < 0.01 || muted }

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
    func start(session: AVAudioSession) {
        Mute.shared.notify = {muted in self.muted = muted }
        Mute.shared.isPaused = false
        sessionVolumeObserver = session.observe(\.outputVolume, options: [.initial, .new]) { session, _ in
            self.volume = session.outputVolume
        }
    }

    /**
     Stop monitoring the output volume of an AVAudioSession
     */
    func stop() {
        guard !Mute.shared.isPaused else { return }
        Mute.shared.notify = nil
        Mute.shared.isPaused = true
        sessionVolumeObserver?.invalidate()
        sessionVolumeObserver = nil
    }

    private func update() {
        keyboard.isMuted = isSilenced
        notePlayer.isMuted = isSilenced
    }
}
