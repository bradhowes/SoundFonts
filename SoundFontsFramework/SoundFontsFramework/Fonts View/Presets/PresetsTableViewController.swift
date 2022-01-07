// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVFoundation
import os

/// View controller for the UITableView showing the presets of a sound font
public final class PresetsTableViewController: UITableViewController {
  private lazy var log = Logging.logger("PresetsTableViewController")

  private var searchBarIsVisibleBeforeLayout: Bool = false

  @IBOutlet public weak var searchBar: UISearchBar!

  public typealias OneShotLayoutCompletionHandler = (() -> Void)
  public var oneShotLayoutCompletionHandler: OneShotLayoutCompletionHandler?

  private var presetsTableViewManager: PresetsTableViewManager!
}

extension PresetsTableViewController {

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    presetsTableViewManager.selectActive(animated: false)
  }

  public override func viewWillLayoutSubviews() {
    searchBarIsVisibleBeforeLayout = presetsTableViewManager.searchBarIsVisible
  }

  public override func viewDidLayoutSubviews() {
    os_log(.debug, log: log, "viewDidLayoutSubviews")
    super.viewDidLayoutSubviews()
    if !searchBarIsVisibleBeforeLayout {
      presetsTableViewManager.hideSearchBar(animated: false)
    }

    if oneShotLayoutCompletionHandler != nil {
      oneShotLayoutCompletionHandler?()
      oneShotLayoutCompletionHandler = nil
      presetsTableViewManager.selectActive(animated: false)
    }
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    if !presetsTableViewManager.searchBarIsVisible {
      coordinator.animate { _ in self.presetsTableViewManager.hideSearchBar(animated: true) } completion: { _ in }
    }
  }
}

extension PresetsTableViewController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    presetsTableViewManager = PresetsTableViewManager(viewController: self,
                                                      activePresetManager: router.activePresetManager,
                                                      selectedSoundFontManager: router.selectedSoundFontManager,
                                                      soundFonts: router.soundFonts,
                                                      favorites: router.favorites,
                                                      keyboard: router.keyboard,
                                                      infoBar: router.infoBar,
                                                      settings: router.settings)
    presetsTableViewManager?.selectActive(animated: false)
  }
}

extension PresetsTableViewController {

  @objc public func dismissSearchKeyboard() {
    os_log(.info, log: log, "dismissSearchKeyboard")
    if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
      searchBar.resignFirstResponder()
    }
    presetsTableViewManager.hideSearchBar(animated: true)
  }
}
