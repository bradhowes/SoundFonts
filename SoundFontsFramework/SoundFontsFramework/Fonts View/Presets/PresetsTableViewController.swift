// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVFoundation
import os

/// View controller for the UITableView showing the presets of a sound font
public final class PresetsTableViewController: UITableViewController {
  private lazy var log = Logging.logger("PresetsTableViewController")

  // UIViewController also has an isEditing attribute, but it is not tied to the tableView.isEditing value which can
  // lead to bugs.
  public override var isEditing: Bool {
    get { tableView.isEditing }
    set { tableView.isEditing = newValue }
  }

  @IBOutlet public var searchBar: UISearchBar!

  public var beginSearchDueToDrag: Bool = false
  public var isSearching: Bool { searchBar.isFirstResponder }
  private var lastSearchText = ""

  private var presetsTableViewManager: PresetsTableViewManager!
  var scrollToSlot: IndexPath?

  var isSearchBarVisible: Bool { self.tableView.contentOffset.y < searchBar.frame.height }

  typealias AfterReloadDataAction = () -> Void
  var afterReloadDataAction: AfterReloadDataAction?
}

extension PresetsTableViewController {

  public override func viewDidLoad() {
    super.viewDidLoad()

    tableView.sectionIndexColor = .darkGray
    tableView.register(TableCell.self)

    searchBar.delegate = self

    // Don't show the search bar due to elongation of table view when the effects view disappears.
    NotificationCenter.default.addObserver(forName: .hidingEffects, object: nil, queue: nil) { _ in
      DispatchQueue.main.async {
        os_log(.info, log: self.log, "hiding effects view -- hiding search bar")
        self.hideSearchBar()
      }
    }
  }

  public override func viewWillAppear(_ animated: Bool) {
    os_log(.info, log: log, "viewWillAppear BEGIN")
    super.viewWillAppear(animated)
    os_log(.info, log: log, "viewWillAppear END")
  }

  public override func viewWillLayoutSubviews() {
    // os_log(.info, log: log, "viewWillLayoutSubviews BEGIN")
    super.viewWillLayoutSubviews()
    // os_log(.info, log: log, "viewWillLayoutSubviews END")
  }

  public override func viewDidLayoutSubviews() {
    os_log(.info, log: log, "viewDidLayoutSubviews BEGIN")
    super.viewDidLayoutSubviews()

    if isEditing {
      hideSearchBarIfVisible()
      os_log(.info, log: log, "viewDidLayoutSubviews END")
      return
    }

    // While the table is moving, record if the searchBar is visible.
    if tableView.isDragging || tableView.isDecelerating {
      beginSearchDueToDrag = isSearchBarVisible
    }
    else {
      // If searchBar was visible at end of drag, begin search. Otherwise, make sure that the searchBar stays hidden.
      if beginSearchDueToDrag {
        beginSearchDueToDrag = false
        beginSearch()
      }
      else {
        if let action = afterReloadDataAction {
          os_log(.info, log: log, "viewDidLayoutSubviews - running action")
          afterReloadDataAction = nil
          action()
        }

         scrollToActiveSlot()
         hideSearchBarIfVisible()
      }
    }

    os_log(.info, log: log, "viewDidLayoutSubviews END")
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    os_log(.debug, log: log, "viewWillTransition BEGIN")
    if isSearchBarVisible {
      coordinator.animate { _ in self.hideSearchBar() } completion: { _ in }
    }
    os_log(.debug, log: log, "viewWillTransition END")
  }

  public func scrollToActiveSlot() {
    if let scrollToSlot = self.scrollToSlot {
      os_log(.info, log: log, "scrollToActiveSlot %d/%d", scrollToSlot.section, scrollToSlot.row)
      tableView.scrollToRow(at: scrollToSlot, at: .none, animated: false)
      self.scrollToSlot = nil
    }
  }
}

// MARK: - UITableViewDataSource Protocol

public extension PresetsTableViewController {

  override func numberOfSections(in tableView: UITableView) -> Int {
    presetsTableViewManager.sectionCount
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    presetsTableViewManager.numberOfRows(section: section)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    presetsTableViewManager.update(cell: tableView.dequeueReusableCell(at: indexPath) as TableCell, at: indexPath)
  }

  override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    if isSearching { return nil}
    let titles = presetsTableViewManager.sectionIndexTitles
    if isEditing { return titles }
    return [UITableView.indexSearch, "•"] + titles
  }

  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    if index == 0 {
      if !isEditing {
        DispatchQueue.main.async { self.beginSearch() }
      }
      return 0
    }
    return index - 1
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0.0 : 18.0
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "\(section * IndexPath.sectionSize)"
  }
}

// MARK: - UITableViewDelegate Protocol

public extension PresetsTableViewController  {

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    os_log(.debug, log: log, "tableView.didSelectRow")
    if isEditing {
      presetsTableViewManager.setSlotVisibility(at: indexPath, state: true)
      return
    }

    presetsTableViewManager.selectSlot(at: indexPath)
    if isSearching {
      endSearch()
    }
  }

  override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    os_log(.debug, log: log, "tableView.didDeselectRow")
    if isEditing {
      presetsTableViewManager.setSlotVisibility(at: indexPath, state: false)
    }
  }

  override func tableView(_ tableView: UITableView,
                          leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    // showingSearchResults ? nil : leadingSwipeActions(at: indexPath)
    return nil
  }

  override func tableView(_ tableView: UITableView,
                          trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    // showingSearchResults ? nil : trailingSwipeActions(at: indexPath)
    return nil
  }

  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    guard let header = view as? UITableViewHeaderFooterView else { return }
    header.textLabel?.textColor = .systemTeal
    header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    header.backgroundView = UIView()
    header.backgroundView?.backgroundColor = .black
  }
}

// MARK: - Preset visibility editing

extension PresetsTableViewController {

  func toggleVisibilityEditing(_ sender: AnyObject) {
    guard let soundFont = presetsTableViewManager.selectedSoundFont else { return }
    let button = sender as? UIButton
    button?.tintColor = isEditing ? .systemTeal : .systemOrange
    if isEditing == false {
      searchBar.endSearch()
      presetsTableViewManager.cancelSearch()
      afterReloadDataAction = { self.beginVisibilityEditing(for: soundFont) }
    } else {
      endVisibilityEditing(for: soundFont)
    }
  }

  private func beginVisibilityEditing(for soundFont: SoundFont) {
    os_log(.info, log: log, "beginVisibilityEditing BEGIN")
    tableView.setEditing(true, animated: true)
    let changes = presetsTableViewManager.applyVisibilityChanges(soundFont: soundFont, isEditing: true)
    tableView.performBatchUpdates {
      tableView.reloadSectionIndexTitles()

      // ???
      if tableView.contentOffset.y == searchBar.frame.height {
        tableView.contentOffset = .zero
      }
      if !changes.isEmpty {
        self.tableView.insertRows(at: changes, with: .none)
      }
    } completion: { _ in
      self.presetsTableViewManager.initializeVisibilitySelections(soundFont: soundFont)
    }

    os_log(.info, log: log, "beginVisibilityEditing END")
  }

  private func endVisibilityEditing(for soundFont: SoundFont) {
    CATransaction.begin()
    CATransaction.setCompletionBlock {
      self.presetsTableViewManager.calculateSectionRowCounts(reload: true)
    }

    tableView.setEditing(false, animated: true)
    let changes = presetsTableViewManager.applyVisibilityChanges(soundFont: soundFont, isEditing: false)
    tableView.performBatchUpdates {
      tableView.deleteRows(at: changes, with: .automatic)
    } completion: { _ in }

    CATransaction.commit()
  }
}

// MARK: Searching

extension PresetsTableViewController: UISearchBarDelegate {

  public func beginSearch() {
    guard searchBar.isFirstResponder == false else { return }
    let offset: CGPoint = .init(x: self.tableView.contentOffset.x, y: 0)
    UIView.animate(withDuration: 0.25) {
      self.tableView.contentOffset = offset
      self.searchBar.beginSearch(with: self.lastSearchText)
    } completion: { _ in
      self.presetsTableViewManager.search(for: self.lastSearchText)
    }
  }

  public func endSearch() {
    lastSearchText = searchBar.nonNilSearchTerm
    searchBar.endSearch()
    presetsTableViewManager.cancelSearch()
    UIView.animate(withDuration: 0.25) {
      self.hideSearchBar()
    }
  }

  public func hideSearchBarIfVisible() {
    os_log(.debug, log: log, "hideSearchIfVisible BEGIN")
    if !isSearching && isSearchBarVisible {
      os_log(.debug, log: log, "hideSearchIfVisible - hiding")
      hideSearchBar()
    }
    os_log(.debug, log: log, "hideSearchIfVisible END")
  }

  private func hideSearchBar() {
    if isSearchBarVisible {
      self.tableView.contentOffset = .init(x: self.tableView.contentOffset.x, y: searchBar.frame.height)
    }
  }

  /**
   Notification from searchBar that the text value changed. NOTE: this is not invoked when programmatically set.

   - parameter searchBar: the UISearchBar where the change took place
   - parameter searchText: the current search term
   */
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    os_log(.debug, log: log, "searchBar.textDidChange - %{public}s", searchText)
    guard let term = searchBar.searchTerm else {
      lastSearchText = ""
      presetsTableViewManager.cancelSearch()
      return
    }
    presetsTableViewManager.search(for: term)
    lastSearchText = term
  }

  public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    os_log(.debug, log: log, "searchBarTextDidEndEditing - %d", searchBar.isFirstResponder)
    endSearch()
  }

  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    os_log(.debug, log: log, "searchBarSearchButtonClicked - %d", searchBar.isFirstResponder)
    endSearch()
  }
}

extension PresetsTableViewController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    let infoBar = router.infoBar
    infoBar.addEventClosure(.editVisibility, self.toggleVisibilityEditing)

    infoBar.addEventClosure(.hideMoreButtons) { [weak self] _ in
      guard let self = self, self.isEditing else { return }
      self.toggleVisibilityEditing(self)
      infoBar.resetButtonState(.editVisibility)
    }

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
