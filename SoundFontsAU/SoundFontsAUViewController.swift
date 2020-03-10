// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework

public class SoundFontsAUViewController: AUViewController, AUAudioUnitFactory {
    private let sampler = Sampler(mode: .audiounit)
    private var components: Components<SoundFontsAUViewController>!
    private var myKVOContext = 0
    private var audioUnit: SoundFontsAU?

    public override func viewDidLoad() {
        super.viewDidLoad()
        components = Components<SoundFontsAUViewController>(changer: .audioUnit)
        components.setMainViewController(self)
    }

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        self.audioUnit = try SoundFontsAU(componentDescription: componentDescription, sampler: sampler,
                                          activePatchManager: components.activePatchManager)
        return self.audioUnit!
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
            useActivePatchKind(new, playSample: playSample)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind, playSample: Bool) {
        _ = self.sampler.load(activePatchKind: activePatchKind, playSample: playSample)
    }
}
