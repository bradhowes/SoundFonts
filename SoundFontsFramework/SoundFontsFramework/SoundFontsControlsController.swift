// Copyright © 2018 Brad Howes. All rights reserved.

import AVKit
import UIKit
import os

/// Top-level view controller for the application. It contains the Sampler which will emit sounds based on what keys are
/// touched. It also starts the audio engine when the application becomes active, and stops it when the application goes
/// to the background or stops being active.
public final class SoundFontsControlsController: UIViewController {

  private lazy var logger = Logging.logger("SoundFontsControlsController")

  @IBOutlet private weak var favoritesView: UIView!
  @IBOutlet private weak var presetsView: UIView!
  @IBOutlet private weak var effectsHeightConstraint: NSLayoutConstraint!
  @IBOutlet private weak var effectsBottomConstraint: NSLayoutConstraint!

  private var upperViewManager: SlidingViewManager!
  private var fontsViewManager: FontsViewManager!
  private var infoBar: InfoBar!

  private var isMainApp: Bool = false

  public override func viewDidLoad() {
    super.viewDidLoad()

    let showingFavorites: Bool = {
      if CommandLine.arguments.contains("--screenshots") { return false }
      return Settings.shared.showingFavorites
    }()

    presetsView.isHidden = showingFavorites
    favoritesView.isHidden = !showingFavorites
    upperViewManager = SlidingViewManager(active: showingFavorites ? 1 : 0)

    upperViewManager.add(view: presetsView)
    upperViewManager.add(view: favoritesView)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if isMainApp && Settings.shared.showEffects {
      showEffects(false)
    }

    updateInfoBarButtons()
  }
}

// MARK: - Controller Configuration

extension SoundFontsControlsController: ControllerConfiguration {

  /**
   Establish connections with other managers / controllers.

   - parameter context: the RunContext that holds all of the registered managers / controllers
   */
  public func establishConnections(_ router: ComponentContainer) {

    fontsViewManager = router.fontsViewManager
    fontsViewManager.addEventClosure(.swipeLeft, showNextConfigurationView)

    let favoritesViewManager = router.favoritesViewManager
    favoritesViewManager.addEventClosure(.swipeRight, showPreviousConfigurationView)

    infoBar = router.infoBar
    infoBar.addEventClosure(.doubleTap, toggleConfigurationViews)
    infoBar.addEventClosure(.showEffects, toggleShowEffects)

    isMainApp = router.isMainApp
  }

  private func toggleConfigurationViews(_ action: AnyObject) {
    if upperViewManager.active == 0 {
      showNextConfigurationView(action)
    } else {
      showPreviousConfigurationView(action)
    }
    AskForReview.maybe()
  }
}

extension SoundFontsControlsController {

  private var showingEffects: Bool { effectsBottomConstraint.constant == 0.0 }

  private func toggleShowEffects(_ sender: AnyObject) {
    let button = sender as? UIButton
    if showingEffects {
      hideEffects()
    } else {
      showEffects()
    }
    button?.tintColor = showingEffects ? .systemOrange : .systemTeal
  }

  private func showEffects(_ animated: Bool = true) {
    effectsBottomConstraint.constant = 0.0
    if animated {
      UIViewPropertyAnimator.runningPropertyAnimator(
        withDuration: 0.25, delay: 0.0,
        options: [.allowUserInteraction, .curveEaseIn],
        animations: self.view.layoutIfNeeded
      ) { _ in
        NotificationCenter.default.post(name: .showingEffects, object: nil)
      }
    }
    Settings.shared.showEffects = true
  }

  private func hideEffects(_ animated: Bool = true) {
    effectsBottomConstraint.constant = effectsHeightConstraint.constant + 8
    if animated {
      UIViewPropertyAnimator.runningPropertyAnimator(
        withDuration: 0.25, delay: 0.0,
        options: [.allowUserInteraction, .curveEaseOut],
        animations: self.view.layoutIfNeeded
      ) { _ in
        NotificationCenter.default.post(name: .hidingEffects, object: nil)
      }
    }
    Settings.shared.showEffects = false
  }
}

extension SoundFontsControlsController {

  /**
   Show the next (right) view in the space above the info bar.
   */
  private func showNextConfigurationView(_ action: AnyObject) {
    if upperViewManager.active == 0 {
      fontsViewManager.dismissSearchKeyboard()
    }
    upperViewManager.slideNextHorizontally()
    Settings.shared.showingFavorites = upperViewManager.active == 1
    updateInfoBarButtons()
  }

  /**
   Show the previous (left) view in the space above the info bar.
   */
  private func showPreviousConfigurationView(_ action: AnyObject) {
    upperViewManager.slidePrevHorizontally()
    Settings.shared.showingFavorites = upperViewManager.active == 1
    updateInfoBarButtons()
  }

  private func updateInfoBarButtons() {
    infoBar.updateButtonsForPresetsViewState(visible: upperViewManager.active == 0)
  }
}

extension SoundFontsControlsController: SegueHandler {

  public enum SegueIdentifier: String {
    case guidedView
    case favorites
    case soundFontPresets
    case infoBar
    case effects
  }
}
