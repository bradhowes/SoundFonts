// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public class SoundFontsAUViewController: AUViewController {
    private let log = Logging.logger("ViewC")
    private let noteInjector = NoteInjector()

    private var components: Components<SoundFontsAUViewController>!
    private var audioUnit: SoundFontsAU?

    override public func viewDidLoad() {
        os_log(.error, log: log, "viewDidLoad")
        super.viewDidLoad()
        components = Components<SoundFontsAUViewController>(inApp: false)
        components.setMainViewController(self)
    }
}

extension SoundFontsAUViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        os_log(.error, log: log, "createAudioUnit")
        let audioUnit = try SoundFontsAU(componentDescription: componentDescription, sampler: components.sampler, activePatchManager: components.activePatchManager)
        self.audioUnit = audioUnit
        return audioUnit
    }
}

// MARK: - Controller Configuration

extension SoundFontsAUViewController: ControllerConfiguration {

    /**
     Establish connections with other managers / controllers.

     - parameter context: the RunContext that holds all of the registered managers / controllers
     */
    public func establishConnections(_ router: ComponentContainer) {
        router.activePatchManager.subscribe(self, notifier: activePatchChange)
        useActivePatchKind(playSample: false)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: _, playSample: playSample) = event {
            os_log(.error, log: log, "activePatchChange - playSample: %d", playSample)
            useActivePatchKind(playSample: playSample)
        }
    }

    private func useActivePatchKind(playSample: Bool) {
        os_log(.error, log: log, "useActivePatchKind - playSample: %d", playSample)
        let sampler = components.sampler
        _ = sampler.load() {
            if playSample {
                self.noteInjector.postMIDI(to: sampler)
            }
        }
    }
}
