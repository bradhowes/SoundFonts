// Created by Akram Hussein on 08/09/2017. Adaptations by Brad Howes

import AudioToolbox
import SoundFontsFramework
import os

final class MuteDetector {
    private let log = Logging.logger("MuteD")

    /// Type of the closure to invoke on mute state change
    public typealias MutedStateChangeClosure = (_ mute: Bool) -> Void

    /// Closure to invoke when the detected mute state changes
    public var notifier: MutedStateChangeClosure?

    /// Current detected mute state
    public private(set) var muted = false

    private let soundUrl: URL = {
        guard let muteSoundUrl = Bundle.main.url(forResource: "mute", withExtension: "aiff") else {
            fatalError("mute.aiff not found")
        }
        return muteSoundUrl
    }()

    private var running = false
    private var scheduled = false

    private let soundId: SystemSoundID
    private let checkInterval: Int

    /**
     Create a new mute detector

     - parameter checkInterval: number of seconds between checks
     */
    init?(checkInterval: Int) {
        var soundId: SystemSoundID = 1
        var yes: UInt32 = 1
        guard AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId) == kAudioServicesNoError,
              AudioServicesSetProperty(kAudioServicesPropertyIsUISound, UInt32(MemoryLayout.size(ofValue: soundId)),
                                       &soundId, UInt32(MemoryLayout.size(ofValue: yes)),
                                       &yes) == kAudioServicesNoError else {
            os_log(.error, log: log, "failed AudioServicesCreateSystemSoundID")
            return nil
        }
        self.soundId = soundId
        self.checkInterval = checkInterval
    }

    deinit {
        guard soundId != 0 else { return }
        AudioServicesRemoveSystemSoundCompletion(soundId)
        AudioServicesDisposeSystemSoundID(soundId)
    }
}

extension MuteDetector {

    /**
     Begin the detector.
     */
    func start() {
        guard !running else { return }
        os_log(.info, log: log, "start")
        running = true
        schedulePlaySound()
    }

    /**
     Stop the detector.
     */
    func stop() {
        guard running else { return }
        os_log(.info, log: log, "stop")
        running = false
    }
}

extension MuteDetector {

    private func schedulePlaySound() {
        guard !scheduled && running else { return }
        scheduled = true
        DispatchQueue.global(qos: .background).asyncLater(interval: .seconds(1)) {
            self.scheduled = false
            guard self.running else { return }
            self.playSound()
        }
    }

    private func playSound() {
        guard running else { return }
        schedulePlaySound()
        let startTime = Date.timeIntervalSinceReferenceDate
        AudioServicesPlaySystemSoundWithCompletion(soundId) { [weak self] in self?.soundFinishedPlaying(startTime) }
    }

    private func soundFinishedPlaying(_ startTime: TimeInterval) {
        let elapsed = Date.timeIntervalSinceReferenceDate - startTime
        let muted = elapsed < 0.1
        if self.muted != muted {
            self.muted = muted
            DispatchQueue.main.async { self.notifier?(muted) }
        }
    }
}
