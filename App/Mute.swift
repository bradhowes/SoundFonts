// Created by Akram Hussein on 08/09/2017. Adaptations by Brad Howes

import AudioToolbox
import SoundFontsFramework
import os

final class MuteDetector {
    private let log = Logging.logger("MuteD")

    public typealias MutedStateChangeClosure = (_ mute: Bool) -> Void

    public var notifier: MutedStateChangeClosure?

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

    init?(checkInterval: Int) {
        var soundId: SystemSoundID = 1
        var yes: UInt32 = 1
        guard AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId) == kAudioServicesNoError,
              AudioServicesSetProperty(kAudioServicesPropertyIsUISound, UInt32(MemoryLayout.size(ofValue: soundId)),
                                       &soundId, UInt32(MemoryLayout.size(ofValue: yes)), &yes) == kAudioServicesNoError else {
            print("Failed to setup sound player")
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

    func start() {
        guard !running else { return }
        os_log(.info, log: log, "start")
        running = true
        schedulePlaySound()
    }

    func stop() {
        guard running else { return }
        os_log(.info, log: log, "stop")
        running = false
    }

    private func schedulePlaySound() {
        guard !scheduled && running else { return }
        os_log(.debug, log: log, "schedulePlaySound")
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
