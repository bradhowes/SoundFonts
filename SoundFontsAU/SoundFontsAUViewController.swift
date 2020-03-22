// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public class SoundFontsAUViewController: AUViewController, AUAudioUnitFactory {
    private let log = Logging.logger("ViewC")
    private let sampler = Sampler(mode: .audiounit)
    private var components: Components<SoundFontsAUViewController>!
    private var myKVOContext = 0
    private var audioUnit: SoundFontsAU?
    fileprivate let noteInjector = NoteInjector()

    override public func viewDidLoad() {
        os_log(.error, log: log, "viewDidLoad")
        super.viewDidLoad()
        components = Components<SoundFontsAUViewController>(changer: .audioUnit)
        components.setMainViewController(self)
    }

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        os_log(.error, log: log, "createAudioUnit")
        let audioUnit = try SoundFontsAU(componentDescription: componentDescription, sampler: sampler,
                                         activePatchManager: components.activePatchManager)
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
        useActivePatchKind(router.activePatchManager.active, playSample: false)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new, playSample: playSample) = event {
            os_log(.error, log: log, "activePatchChange - playSample: %d", playSample)
            useActivePatchKind(new, playSample: playSample)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind, playSample: Bool) {
        os_log(.error, log: log, "useActivePatchKind - playSample: %d", playSample)
        // guard let audioUnit = self.audioUnit else { return }
        _ = self.sampler.load(activePatchKind: activePatchKind) {
            if playSample {
                self.noteInjector.postMIDI(to: self.sampler)
            }
        }
    }
}
