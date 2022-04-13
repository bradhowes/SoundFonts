// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import AVFoundation
import os

/// View controller for the UITableView showing the presets of a sound font
public final class PresetsTableViewController: UITableViewController {
  private lazy var log = Logging.logger("PresetsTableViewController")

  /// Text field for entering preset search queries.
  @IBOutlet public var searchBar: UISearchBar!
  private var infoBar: InfoBar!

  /// True when user is searching
  public var isSearching: Bool { searchBar.isFirstResponder }

  public typealias AfterReloadDataAction = () -> Void

  /// Closure to execute after the table view performs `layoutSubviews`. This is reset to nil in `viewDidLayoutSubviews`.
  public var afterReloadDataAction: AfterReloadDataAction?

  /// A row to make visible after the table view performs `layoutSubviews`. This is reset to nil in `viewDidLayoutSubviews`.
  public var slotToScrollTo: IndexPath? {
    didSet {
      os_log(.debug, log: log, "slotToScrollTo: %{public}s", slotToScrollTo.descriptionOrNil)
      if slotToScrollTo == lastSelectedSlot {
        slotToScrollTo = nil
      }
    }
  }

  private var lastSelectedSlot: IndexPath? {
    didSet { os_log(.debug, log: log, "lastSelectedSlot: %{public}s", lastSelectedSlot.descriptionOrNil) }
  }

  private var lastSearchText = ""
  private var presetsTableViewManager: PresetsTableViewManager!
  private let presetSectionHeaderIdentifier = "presetSectionHeader"
}

extension PresetsTableViewController {

  public override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(TableCell.self)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableView.automaticDimension

    // Only show section view if there are enough items to justify having one.
    tableView.sectionIndexMinimumDisplayRowCount = IndexPath.sectionSize + 1
    tableView.sectionIndexColor = .darkGray
    tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: presetSectionHeaderIdentifier)
    searchBar.delegate = self
  }

  public override func viewWillAppear(_ animated: Bool) {
    os_log(.debug, log: log, "viewWillAppear BEGIN")
    super.viewWillAppear(animated)
    if tableView.numberOfRows(inSection: 0) == 0 {
      presetsTableViewManager?.regenerateViewSlots()
    }
    os_log(.debug, log: log, "viewWillAppear END")
  }

  /**
   Notification that the table view has performed `layoutSubviews`. Here we perform actions that needed to wait until the
   table view was updated.
   */
  public override func viewDidLayoutSubviews() {
    os_log(.debug, log: log, "viewDidLayoutSubviews BEGIN")
    super.viewDidLayoutSubviews()

    if !isEditing && !isSearching && tableView.isDragging && tableView.contentOffset.y < -60 {
      beginSearch()
      return
    }

    if let action = afterReloadDataAction {
      os_log(.debug, log: log, "viewDidLayoutSubviews - running action")
      afterReloadDataAction = nil
      action()
    }

    if isSearching {
      os_log(.debug, log: log, "viewDidLayoutSubviews END - isSearching")
      return
    }

    if let indexPath = slotToScrollTo {
      slotToScrollTo = nil
      if indexPath.row < tableView.visibleCells.count {
        os_log(.debug, log: log, "viewDidLayoutSubviews - A slotToScrollTo %{public}s", indexPath.description)
        tableView.scrollToRow(at: IndexPath(row: 0, section: indexPath.section), at: .top, animated: false)
      } else {
        os_log(.debug, log: log, "viewDidLayoutSubviews - slotToScrollTo %{public}s", indexPath.description)
        tableView.scrollToRow(at: indexPath, at: .none, animated: false)
      }
    }

    os_log(.debug, log: log, "viewDidLayoutSubviews END")
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
    (isSearching || isEditing) ? nil : ([UITableView.indexSearch, "•"] + presetsTableViewManager.sectionIndexTitles)
  }

  override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    if index == 0 {
      if !isEditing {
        // Need to do this because the view may update due to the section touch.
        DispatchQueue.main.async { self.beginSearch() }
      }
      return 0
    }
    return index - 1
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

    // Don't let `viewDidLayoutSubviews` reposition the selected row
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

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0.0 : 18.0
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section > 0 else { return nil }
    guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: presetSectionHeaderIdentifier) else { return nil }
    view.textLabel?.textColor = .systemTeal
    view.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    view.backgroundView = UIView()
    view.backgroundView?.backgroundColor = .black
    return view
  }

  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    0.0
  }

  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    nil
  }
}

// MARK: - Preset visibility editing

extension PresetsTableViewController {

  /**
   Toggle the edit visibility action.

   - parameter sender: the button that was touched
   */
  func toggleVisibilityEditing(_ sender: AnyObject) {
    let button = sender as? UIButton
    button?.tintColor = isEditing ? .systemTeal : .systemOrange
    if isEditing == false {

      // If user was searching, cancel out of it.
      searchBar.endSearch()
      presetsTableViewManager.cancelSearch()

      // Begin editing after next `layoutSubviews`.
      afterReloadDataAction = { self.beginVisibilityEditing() }
    } else {
      endVisibilityEditing()
    }
  }

  private func beginVisibilityEditing() {
    os_log(.debug, log: log, "beginVisibilityEditing BEGIN")

    // We show currently-hidden items but we don't update existing IndexPath values. This is fast and not complicated,
    // but our section counts will be off so it requires a reloadData() at the end of the editing to bring everything
    // back into sync. The result as written looks nice with no animation disruptions.
    //
    guard let insertions = presetsTableViewManager.beginVisibilityEditing() else { return }

    tableView.performBatchUpdates {
      tableView.reloadSectionIndexTitles()
      self.tableView.insertRows(at: insertions, with: .none)

      // Set editing mode here in order to have the inserted cells above in editing mode.
      setEditing(true, animated: true)
    } completion: { _ in
      self.showVisibilityState()
    }

    os_log(.debug, log: log, "beginVisibilityEditing END")
  }

  private func showVisibilityState() {
    os_log(.debug, log: self.log, "showVisibilityState")
    for (indexPath, isVisible) in presetsTableViewManager.visibilityState where isVisible {
      tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
    }
  }

  func endVisibilityEditing() {

    // This seems to be the best way to end visibility editing without any animation hick-ups.
    CATransaction.begin()
    CATransaction.setCompletionBlock {
      self.presetsTableViewManager.regenerateViewSlots()
    }

    setEditing(false, animated: true)
    if let deletions = presetsTableViewManager.endVisibilityEditing() {
      tableView.performBatchUpdates {
        tableView.deleteRows(at: deletions, with: .automatic)
        self.infoBar.resetButtonState(.editVisibility)
      } completion: { _ in }
    }

    CATransaction.commit()
  }
}

// MARK: Searching

extension PresetsTableViewController: UISearchBarDelegate {

  private func beginSearch() {
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

  private func endSearch() {
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

// MARK: ControllerConfiguration

extension PresetsTableViewController: ControllerConfiguration {

  public func establishConnections(_ router: ComponentContainer) {
    infoBar = router.infoBar
    infoBar.addEventClosure(.editVisibility, self.toggleVisibilityEditing)

    infoBar.addEventClosure(.hideMoreButtons) { [weak self] _ in
      guard let self = self, self.isEditing else { return }
      self.endVisibilityEditing()
    }

    presetsTableViewManager = PresetsTableViewManager(viewController: self,
                                                      activePresetManager: router.activePresetManager,
                                                      selectedSoundFontManager: router.selectedSoundFontManager,
                                                      soundFonts: router.soundFonts,
                                                      favorites: router.favorites,
                                                      keyboard: router.keyboard,
                                                      infoBar: router.infoBar,
                                                      settings: router.settings)
    tableView.tableHeaderView = nil
  }
}
