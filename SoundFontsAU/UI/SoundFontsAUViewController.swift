// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public class SoundFontsAUViewController: AUViewController, AUAudioUnitFactory {
    private let log = Logging.logger("SFAU")

    private let sampler = Sampler(mode: .audiounit)
    private var components: Components<SoundFontsAUViewController>!
    private var myKVOContext = 0
    private var auAudioUnit: AUAudioUnit { sampler.auAudioUnit! }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let sharedStateMonitor = SharedStateMonitor(changer: .audioUnit)
        components = Components<SoundFontsAUViewController>(sharedStateMonitor: sharedStateMonitor)
        components.setMainViewController(self)
    }

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        if case let .failure(failure) = sampler.start() {
            os_log(.error, log: log, "failed to start sampler - %{public}s", failure.localizedDescription)
        }

        sampler.auAudioUnit!.addObserver(self, forKeyPath: "allParameterValues", options: [.new, .old],
                                         context: &myKVOContext)

        return sampler.auAudioUnit!
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard context == &myKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard let params = sampler.auAudioUnit?.parameterTree else { return }
        for each in params.allParameters {
            os_log(.error, log: log, "%{public}s/%{public}s", each.identifier, each.displayName)
        }
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
        useActivePatchKind(router.activePatchManager.active)
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        if case let .active(old: _, new: new) = event {
            useActivePatchKind(new)
        }
    }

    private func useActivePatchKind(_ activePatchKind: ActivePatchKind) {
        _ = self.sampler.load(activePatchKind: activePatchKind)
    }
}
