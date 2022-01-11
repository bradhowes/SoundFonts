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

  public var isSearching: Bool { searchBar.isFirstResponder }
  private var lastSearchText = ""

  private var presetsTableViewManager: PresetsTableViewManager!

  typealias AfterReloadDataAction = () -> Void

  var afterReloadDataAction: AfterReloadDataAction?

  var slotToScrollTo: IndexPath? {
    didSet {
      os_log(.debug, log: log, "slotToScrollTo: %{public}s", slotToScrollTo.descriptionOrNil)
      if slotToScrollTo == lastSelectedSlot {
        slotToScrollTo = nil
      }
    }
  }

  var lastSelectedSlot: IndexPath? {
    didSet { os_log(.debug, log: log, "lastSelectedSlot: %{public}s", lastSelectedSlot.descriptionOrNil) }
  }
}

extension PresetsTableViewController {

  public override func viewDidLoad() {
    super.viewDidLoad()

    tableView.sectionIndexColor = .darkGray
    tableView.register(TableCell.self)
    searchBar.delegate = self
  }

  public override func viewWillAppear(_ animated: Bool) {
    os_log(.info, log: log, "viewWillAppear BEGIN")
    super.viewWillAppear(animated)

    tableView.tableHeaderView = nil

    os_log(.info, log: log, "viewWillAppear END")
  }

  public override func viewDidLayoutSubviews() {
    os_log(.info, log: log, "viewDidLayoutSubviews BEGIN")
    super.viewDidLayoutSubviews()

    if isEditing {
      os_log(.info, log: log, "viewDidLayoutSubviews END - isEditing")
      return
    }

    if !isSearching && tableView.isDragging && tableView.contentOffset.y < -60 {
      beginSearch()
      return
    }

    if let action = afterReloadDataAction {
      os_log(.info, log: log, "viewDidLayoutSubviews - running action")
      afterReloadDataAction = nil
      action()
    }

    if isSearching {
      os_log(.info, log: log, "viewDidLayoutSubviews END - isSearching")
      return
    }

    if let indexPath = slotToScrollTo {
      slotToScrollTo = nil
      if indexPath.row < tableView.visibleCells.count {
        os_log(.info, log: log, "viewDidLayoutSubviews - A slotToScrollTo %{public}s", indexPath.description)
        tableView.scrollToRow(at: IndexPath(row: 0, section: indexPath.section), at: .top, animated: false)
      } else {
        os_log(.info, log: log, "viewDidLayoutSubviews - slotToScrollTo %{public}s", indexPath.description)
        tableView.scrollToRow(at: indexPath, at: .none, animated: false)
      }
    }

    os_log(.info, log: log, "viewDidLayoutSubviews END")
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    os_log(.debug, log: log, "viewWillTransition BEGIN")
    super.viewWillTransition(to: size, with: coordinator)

    if isSearching {
      endSearch()
      coordinator.animate { _ in } completion: { _ in self.beginSearch() }
    }

    os_log(.debug, log: log, "viewWillTransition END")
  }

  private func scrollToActiveSlot() {
  }
}

// MARK: - UITableViewDataSource Protocol

public extension PresetsTableViewController {

  override func numberOfSections(in tableView: UITableView) -> Int {
    lastSelectedSlot = nil
    return presetsTableViewManager.sectionCount
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
        DispatchQueue.main.async {
          self.beginSearch() }
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

    lastSelectedSlot = indexPath
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
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    return isSearching ? nil : presetsTableViewManager.leadingSwipeActions(at: indexPath, cell: cell)
  }

  override func tableView(_ tableView: UITableView,
                          trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    return isSearching ? nil : presetsTableViewManager.trailingSwipeActions(at: indexPath, cell: cell)
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
    let changes = presetsTableViewManager.calculateVisibilityChanges(soundFont: soundFont, isEditing: true)
    tableView.performBatchUpdates {
      tableView.reloadSectionIndexTitles()
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
    let changes = presetsTableViewManager.calculateVisibilityChanges(soundFont: soundFont, isEditing: false)
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
    tableView.tableHeaderView = searchBar
    UIView.animate(withDuration: 0.25) {
      self.tableView.contentOffset = offset
      self.searchBar.beginSearch(with: self.lastSearchText)
    } completion: { _ in
      self.presetsTableViewManager.search(for: self.lastSearchText)
    }
  }

  public func endSearch() {
    lastSearchText = searchBar.nonNilSearchTerm
    presetsTableViewManager.cancelSearch()
    self.searchBar.endSearch()

    UIView.animate(withDuration: 0.25) {
      self.tableView.contentOffset = .init(x: 0, y: self.searchBar.frame.height)
    } completion: { _ in
      self.tableView.tableHeaderView = nil
      self.tableView.contentOffset = .zero
      self.presetsTableViewManager.showActiveSlot()
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
