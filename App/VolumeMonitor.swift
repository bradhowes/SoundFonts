// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import AVKit
import SoundFontsFramework

/**
 Monitor volume setting on device and the "silence" or "mute" switch. When there is no apparent audio
 output, update the Keyboard and NotePlayer instances so that they can show an indication to the user.
 */
final class VolumeMonitor: NSObject {

    private let keyboard: Keyboard
    private let notePlayer: NotePlayer

    private var volume: Float = 0.0 {
        didSet {
            keyboard.isMuted = isMuted
            notePlayer.isMuted = isMuted
        }
    }

    private var muted = false {
        didSet {
            keyboard.isMuted = isMuted
            notePlayer.isMuted = isMuted
        }
    }

    private var isMuted: Bool { volume < 0.01 || muted }

    private struct Observation {
        static let VolumeKey = "outputVolume"
        static var Context = 0
    }

    private var observer: NSKeyValueObservation?

    /**
     Construct new monitor.

     - parameter keyboard: Keyboard instance that handle key renderings
     - parameter notePlayer: NotePlayer instance that handles note playing
     */
    init(keyboard: Keyboard, notePlayer: NotePlayer) {
        self.keyboard = keyboard
        self.notePlayer = notePlayer
        super.init()
    }

    /**
     Begin monitoring volume of the given AVAudioSession

     - parameter session: the AVAudioSession to monitor
     */
    func start(session: AVAudioSession) {
        Mute.shared.notify = {muted in self.muted = muted }
        Mute.shared.isPaused = false
        observer = session.observe(\.outputVolume, options: [.initial, .new]) { session, _ in
            self.volume = session.outputVolume
        }
    }

    /**
     Stop monitoring the output volume of an AVAudioSession
     */
    func stop() {
        guard Mute.shared.isPaused == false else { return }
        Mute.shared.notify = nil
        Mute.shared.isPaused = true
        observer?.invalidate()
        observer = nil
    }
}
