// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// View controller for the presets UITableView.
public final class PresetsTableViewController: UITableViewController {

  private lazy var log = Logging.logger("PresetsTableViewController")

  @IBOutlet public weak var searchBar: UISearchBar!

  public typealias OneShotLayoutCompletionHandler = (() -> Void)
  public var oneShotLayoutCompletionHandler: OneShotLayoutCompletionHandler?

  private var presetsTableViewManager: PresetsTableViewManager?
}

extension PresetsTableViewController {

  public override func viewDidLoad() {
    super.viewDidLoad()
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    presetsTableViewManager?.selectActive(animated: false)
  }

  public override func viewWillTransition(
    to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(
      alongsideTransition: { _ in
      },
      completion: { _ in
        self.presetsTableViewManager?.selectActive(animated: false)
      })
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    oneShotLayoutCompletionHandler?()
    oneShotLayoutCompletionHandler = nil
  }
}

extension PresetsTableViewController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {

    presetsTableViewManager = PresetsTableViewManager(
      viewController: self,
      activePatchManager: router.activePatchManager,
      selectedSoundFontManager: router.selectedSoundFontManager,
      soundFonts: router.soundFonts,
      favorites: router.favorites,
      keyboard: router.keyboard,
      infoBar: router.infoBar)

    presetsTableViewManager?.selectActive(animated: false)
  }
}

extension PresetsTableViewController {

  public func dismissSearchKeyboard() {
    if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
      searchBar.resignFirstResponder()
      presetsTableViewManager?.hideSearchBar(animated: true)
    }
  }
}
