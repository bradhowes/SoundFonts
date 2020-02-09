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

    init(keyboard: Keyboard, notePlayer: NotePlayer) {
        self.keyboard = keyboard
        self.notePlayer = notePlayer
        super.init()
    }

    func start(session: AVAudioSession) {
        Mute.shared.notify = {muted in self.muted = muted }
        Mute.shared.isPaused = false
        session.addObserver(self, forKeyPath: Observation.VolumeKey, options: [.initial, .new],
                            context: &Observation.Context)
    }

    func stop(session: AVAudioSession) {
        guard Mute.shared.isPaused == false else { return }
        Mute.shared.notify = nil
        Mute.shared.isPaused = true
        session.removeObserver(self, forKeyPath: Observation.VolumeKey, context: &Observation.Context)
    }

    //swiftlint:disable block_based_kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard context == &Observation.Context else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == Observation.VolumeKey {
            if let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue {
                self.volume = volume
            }
        }
    }
    //swiftlint:enable block_based_kvo
}
