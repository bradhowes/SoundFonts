// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVKit
import os

extension SettingKeys {
    static let wasShowingFavorites = SettingKey<Bool>("showingFavorites", defaultValue: false)
}

/**
 Top-level view controller for the application. It contains the Sampler which will emit sounds based on what keys are
 touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
 to the background or stops being active.
 */
public final class SoundFontsControlsController: UIViewController {

    private lazy var logger = Logging.logger("SFCC")

    @IBOutlet private weak var favoritesView: UIView!
    @IBOutlet private weak var patchesView: UIView!
    @IBOutlet private weak var envelopeView: UIView!

    private var components: ComponentContainer!
    private var upperViewManager = SlidingViewManager()

    public override func viewDidLoad() {
        super.viewDidLoad()
        upperViewManager.add(view: patchesView)
        upperViewManager.add(view: favoritesView)
        upperViewManager.add(view: envelopeView)
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

        let showingFavorites: Bool = {
            if CommandLine.arguments.contains("--screenshots") { return false }
            return Settings[.wasShowingFavorites]
        }()

        patchesView.isHidden = showingFavorites
        favoritesView.isHidden = !showingFavorites

        let patchesViewManager = router.patchesViewManager
        patchesViewManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        patchesViewManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))

        let favoritesViewManager = router.favoritesViewManager
        favoritesViewManager.addTarget(.swipeLeft, target: self, action: #selector(showNextConfigurationView))
        favoritesViewManager.addTarget(.swipeRight, target: self, action: #selector(showPreviousConfigurationView))

        router.infoBar.addTarget(.doubleTap, target: self, action: #selector(toggleConfigurationViews))
    }

    @IBAction private func toggleConfigurationViews() {
        if favoritesView.isHidden {
            showNextConfigurationView()
        }
        else {
            showPreviousConfigurationView()
        }
        AskForReview.maybe()
    }

    /**
     Show the next (right) view in the space above the info bar.
     */
    @IBAction public func showNextConfigurationView() {
        if favoritesView.isHidden {
            components.patchesViewManager.dismissSearchKeyboard()
            Settings[.wasShowingFavorites] = favoritesView.isHidden
            upperViewManager.slideNextHorizontally()
            components.guideManager.favoritesGuide()
        }
    }

    /**
     Show the previous (left) view in the space above the info bar.
     */
    @IBAction public func showPreviousConfigurationView() {
        if patchesView.isHidden {
            components.patchesViewManager.dismissSearchKeyboard()
            Settings[.wasShowingFavorites] = favoritesView.isHidden
            upperViewManager.slidePrevHorizontally()
            components.guideManager.soundFontsGuide()
        }
    }
}

extension SoundFontsControlsController: SegueHandler {

    public enum SegueIdentifier: String {
        case guidedView
        case favorites
        case soundFontPatches
        case infoBar
    }
}
