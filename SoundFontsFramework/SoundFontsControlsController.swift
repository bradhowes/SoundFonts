// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit
import os

/**
 Top-level view controller for the application. It contains the Sampler which will emit sounds based on what keys are
 touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
 to the background or stops being active.
 */
public final class SoundFontsControlsController: UIViewController {

    private lazy var logger = Logging.logger("SFCC")

    @IBOutlet private weak var favoritesView: UIView!
    @IBOutlet private weak var patchesView: UIView!

    @IBOutlet weak var blankBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var effectsHeightConstraint: NSLayoutConstraint!

    private var components: ComponentContainer!
    private var upperViewManager: SlidingViewManager!

    public override func viewDidLoad() {
        super.viewDidLoad()

        let showingFavorites: Bool = {
            if CommandLine.arguments.contains("--screenshots") { return false }
            return settings.showingFavorites
        }()

        blankBottomConstraint.constant = 0

        patchesView.isHidden = showingFavorites
        favoritesView.isHidden = !showingFavorites
        upperViewManager = SlidingViewManager(active: showingFavorites ? 1: 0)

        upperViewManager.add(view: patchesView)
        upperViewManager.add(view: favoritesView)
    }
}

// MARK: - Controller Configuration

extension SoundFontsControlsController: ControllerConfiguration {

    /**
     Establish connections with other managers / controllers.

     - parameter context: the RunContext that holds all of the registered managers / controllers
     */
    public func establishConnections(_ router: ComponentContainer) {
        components = router

        let patchesViewManager = router.patchesViewManager
        patchesViewManager.addEventClosure(.swipeLeft, self.showNextConfigurationView)

        let favoritesViewManager = router.favoritesViewManager
        favoritesViewManager.addEventClosure(.swipeLeft, self.showNextConfigurationView)
        favoritesViewManager.addEventClosure(.swipeRight, self.showPreviousConfigurationView)
        router.infoBar.addEventClosure(.doubleTap, self.toggleConfigurationViews)

        router.infoBar.addEventClosure(.showEffects, self.toggleShowEffects)
    }

    private func toggleConfigurationViews(_ action: AnyObject) {
        if upperViewManager.active == 0 {
            showNextConfigurationView(action)
        }
        else {
            showPreviousConfigurationView(action)
        }
        AskForReview.maybe()
    }

    private func toggleShowEffects(_ action: AnyObject) {
        let newValue: CGFloat = blankBottomConstraint.constant == 0.0 ? effectsHeightConstraint.constant : 0.0
        let curve: UIView.AnimationOptions = newValue != 0.0 ? .curveEaseIn : .curveEaseOut
        self.blankBottomConstraint.constant = newValue
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction, curve],
                                                       animations: { self.view.layoutIfNeeded() })
    }

    /**
     Show the next (right) view in the space above the info bar.
     */
    private func showNextConfigurationView(_ action: AnyObject) {
        if upperViewManager.active == 0 {
            components.patchesViewManager.dismissSearchKeyboard()
        }

        upperViewManager.slideNextHorizontally()
        components.guideManager.prepareGuide(for: upperViewManager.active)
        settings.showingFavorites = upperViewManager.active == 1
    }

    /**
     Show the previous (left) view in the space above the info bar.
     */
    private func showPreviousConfigurationView(_ action: AnyObject) {
        upperViewManager.slidePrevHorizontally()
        components.guideManager.prepareGuide(for: upperViewManager.active)
        settings.showingFavorites = upperViewManager.active == 1
    }
}

extension SoundFontsControlsController: SegueHandler {

    public enum SegueIdentifier: String {
        case guidedView
        case favorites
        case soundFontPatches
        case infoBar
        case effects
    }
}
