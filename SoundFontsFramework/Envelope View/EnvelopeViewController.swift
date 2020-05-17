// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os

public class EnvelopeViewController: UIViewController {
    private lazy var log = Logging.logger("EnvVC")

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    private var envelopeSelector: EnvelopeSelector!

    @IBOutlet private weak var env1: UIButton!
    @IBOutlet private weak var env2: UIButton!
    @IBOutlet private weak var both: UIButton!

    @IBOutlet private weak var attack: VSSlider!
    @IBOutlet private weak var decay: VSSlider!
    @IBOutlet private weak var sustain: VSSlider!
    @IBOutlet private weak var ruhlease: VSSlider!

    public override func viewDidLoad() {

        attack.addTapGesture()
        decay.addTapGesture()
        sustain.addTapGesture()
        ruhlease.addTapGesture()
        
        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeLeft)

        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeRight)

        envelopeSelector = EnvelopeSelector(env1: env1, env2: env2, both: both)
        envelopeSelector.delegate = self
    }
}

extension EnvelopeViewController: EnvelopeViewManager {

    public func addTarget(_ event: UpperViewSwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }
}

extension EnvelopeViewController: ControllerConfiguration {

    public func establishConnections(_ router: ComponentContainer) {
        router.activePatchManager.subscribe(self, notifier: activePatchChange(_:))
        router.sampler.subscribe(self, notifier: patchLoaded(_:))
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        os_log(.info, log: log, "activePatchChange")
        switch event {
        case .active(old: _, new: _, playSample: _):
            break
        }
    }

    private func patchLoaded(_ event: SamplerEvent) {
        os_log(.info, log: log, "patchLoaded")
        switch event {
        case .loaded(patch: _):
            break
        }
    }
}

extension EnvelopeViewController: EnvelopeSelectorDelegate {

    func selectionChanged(value: EnvelopeSelected) {
        print("new selection")
    }
}
