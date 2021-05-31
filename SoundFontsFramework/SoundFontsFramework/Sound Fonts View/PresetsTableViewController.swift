// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVFoundation
import os

/// View controller for the UITableView showing the presets of a sound font
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
    presetsTableViewManager?.selectActive(animated: false)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  public override func viewDidLayoutSubviews() {
    os_log(.info, log: log, "viewDidLayoutSubviews - %d %d", isBeingPresented, isBeingDismissed)
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
    os_log(.info, log: log, "dismissSearchKeyboard")
    if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
      searchBar.resignFirstResponder()
    }
    presetsTableViewManager?.hideSearchBar(animated: true)
  }
}
