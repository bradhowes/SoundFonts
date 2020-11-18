// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public final class SoundFontsAUViewController: AUViewController {
    private let log = Logging.logger("SFAUVC")
    private let noteInjector = NoteInjector()
    private let components = Components<SoundFontsAUViewController>(inApp: false)

    private var audioUnit: SoundFontsAU?

    override public func viewDidLoad() {
        os_log(.info, log: log, "viewDidLoad")
        super.viewDidLoad()
        components.setMainViewController(self)
    }
}

extension SoundFontsAUViewController: AUAudioUnitFactory {

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        os_log(.info, log: log, "createAudioUnit")
        let audioUnit = try SoundFontsAU(componentDescription: componentDescription, sampler: components.sampler, activePatchManager: components.activePatchManager)
        os_log(.info, log: log, "created SoundFontsAU")
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
            os_log(.info, log: log, "activePatchChange - playSample: %d", playSample)
            useActivePatchKind(playSample: playSample)
        }
    }

    private func useActivePatchKind(playSample: Bool) {
        os_log(.info, log: log, "useActivePatchKind - playSample: %d", playSample)
        guard audioUnit != nil else { return }
        switch components.sampler.loadActivePreset() {
        case .success: break
        case .failure(let reason):
            switch reason {
            case .noSampler: os_log(.error, log: log, "no sampler")
            case .sessionActivating(let error): os_log(.error, log: log, "failed to activate session: %{public}s", error.localizedDescription)
            case .engineStarting(let error): os_log(.error, log: log, "failed to start engine: %{public}s", error.localizedDescription)
            case .patchLoading(let error): os_log(.error, log: log, "failed to load patch: %{public}s", error.localizedDescription)
            }
        }
    }
}
