// Copyright © 2020 Brad Howes. All rights reserved.

import CoreAudioKit
import SoundFontsFramework
import os

public class SoundFontsAUViewController: AUViewController, AUAudioUnitFactory {
    private let log = Logging.logger("SFAU")

    private let sampler = Sampler(mode: .audiounit)
    private var components: Components<SoundFontsAUViewController>!
    private var myKVOContext = 0
    private var auAudioUnit: AUAudioUnit? { sampler.auAudioUnit }

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

        auAudioUnit?.addObserver(self, forKeyPath: "fullState", options: [.new, .old], context: &myKVOContext)
        return auAudioUnit!
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        guard context == &myKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard let fullState = auAudioUnit?.fullState else { return }
        for each in fullState {
            os_log(.error, log: log, "%{public}s", each.key)
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
        updateFullState(activePatchKind: activePatchKind)
    }

    private func updateFullState(activePatchKind: ActivePatchKind) {
        if let auAudioUnit = self.auAudioUnit {
            var fullState = auAudioUnit.fullState ?? [:]
            fullState["activePatch"] = activePatchKind.soundFontPatch
            auAudioUnit.fullState = fullState
        }
    }
}
