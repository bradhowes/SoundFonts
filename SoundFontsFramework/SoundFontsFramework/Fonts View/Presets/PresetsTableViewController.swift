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

  public override func viewDidLoad() {
    super.viewDidLoad()
    clearsSelectionOnViewWillAppear = false
    NotificationCenter.default.addObserver(forName: .hidingEffects, object: nil, queue: nil) { _ in
      DispatchQueue.main.async {
        os_log(.info, log: self.log, "hiding effects view -- hiding search bar")
        self.presetsTableViewManager.hideSearchBar(animated: true)
      }
    }
  }

  public override func viewWillAppear(_ animated: Bool) {
    os_log(.info, log: log, "viewWillAppear BEGIN")
    super.viewWillAppear(animated)
    presetsTableViewManager.selectActive(animated: false)
    os_log(.info, log: log, "viewWillAppear END")
  }

  public override func viewWillLayoutSubviews() {
    os_log(.info, log: log, "viewWillLayoutSubviews BEGIN")
    super.viewWillLayoutSubviews()
    searchBarIsVisibleBeforeLayout = presetsTableViewManager.searchBarIsVisible
    os_log(.info, log: log, "viewWillLayoutSubviews END")
  }

  public override func viewDidLayoutSubviews() {
    os_log(.info, log: log, "viewDidLayoutSubviews BEGIN")
    super.viewDidLayoutSubviews()

    if !searchBarIsVisibleBeforeLayout {
      os_log(.debug, log: log, "viewDidLayoutSubviews - hiding search bar")
      presetsTableViewManager.hideSearchBar(animated: false)
    }

    if oneShotLayoutCompletionHandler != nil {
      os_log(.debug, log: log, "viewDidLayoutSubviews - running onShotLayoutCompletionHandler")
      oneShotLayoutCompletionHandler?()
      oneShotLayoutCompletionHandler = nil
      presetsTableViewManager.selectActive(animated: false)
    }
    os_log(.info, log: log, "viewDidLayoutSubviews END")
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    os_log(.debug, log: log, "viewWillTransition BEGIN")
    if !presetsTableViewManager.searchBarIsVisible {
      coordinator.animate { _ in self.presetsTableViewManager.hideSearchBar(animated: true) } completion: { _ in }
    }
    os_log(.debug, log: log, "viewWillTransition END")
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
  }
}

extension PresetsTableViewController {

  @objc public func dismissSearchKeyboard() {
    os_log(.info, log: log, "dismissSearchKeyboard BEGIN")
    if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
      searchBar.resignFirstResponder()
    }
    presetsTableViewManager.hideSearchBar(animated: true)
    os_log(.info, log: log, "dismissSearchKeyboard END")
  }
}
