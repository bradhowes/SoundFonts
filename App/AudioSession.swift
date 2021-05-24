// Copyright © 2020 Brad Howes. All rights reserved.

import SoundFontsFramework
import AVKit
import os

/**
 Configures the AVAudioSession for the app.
 */
struct AudioSession {
    private static let log = Logging.logger("AudioSession")

    /**
     Configure the AVAudioSession to what we want.

     - parameter sampleRate: the preferred sample rate to use for audio output
     - parameter bufferSize: the preferred number of samples to buffer for audio output
     */
    static func configure(sampleRate: Double = 44100.0, bufferSize: Int = 512) {

        // Set the category and mode of audio playback.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
        } catch let error as NSError {
            fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        do {
            try audioSession.setPreferredSampleRate(sampleRate)
        } catch let error as NSError {
            os_log(.error, log: log, "Failed to set the preferred sample rate to %f: %{public}s",
                   sampleRate, error.localizedDescription)
        }

        do {
            try audioSession.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
        } catch let error as NSError {
            os_log(.error, log: log, "Failed to set the preferred buffer size to %d: %{public}s",
                   bufferSize, error.localizedDescription)
        }
    }
}
