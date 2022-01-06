// Copyright © 2018 Brad Howes. All rights reserved.
import UIKit
import os

/// Number of sections we partition presets into
private let sectionSize = 20

private enum Slot: Equatable {
  case preset(index: Int)
  case favorite(key: Favorite.Key)
}

/**
 Data source and delegate for the presets UITableView. This is one of the most complicated managers and it should be
 broken up into smaller components. There are three four areas of functionality:

 - table view drawing and selecting
 - row visibility editing
 - searching
 - row swiping
 */
final class PresetsTableViewManager: NSObject {
  private lazy var log = Logging.logger("PresetsTableViewManager")

  private let viewController: PresetsTableViewController
  private var view: UITableView { viewController.tableView }

  private var lastSearchText = ""
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePresetManager: ActivePresetManager
  private let soundFonts: SoundFonts
  private let favorites: Favorites
  private let keyboard: Keyboard?
  private let infoBar: InfoBar
  private let settings: Settings

  private var viewSlots = [Slot]()
  private var searchSlots: [Slot]?
  private var sectionRowCounts = [Int]()

  private var searchBar: UISearchBar { viewController.searchBar }
  private var showingSearchResults: Bool { searchSlots != nil }

  /**
   Construct a new presets table view manager.

   - parameter viewController: the view controller that holds this manager
   - parameter activePresetManager: the active preset manager
   - parameter selectedSoundFontManager: the selected sound font manager
   - parameter soundFonts: the sound fonts collection manager
   - parameter favorites: the favorites collection manager
   - parameter keyboard: the optional keyboard view manager
   - parameter infoBar: the info bar manager
   */
  init(viewController: PresetsTableViewController, activePresetManager: ActivePresetManager,
       selectedSoundFontManager: SelectedSoundFontManager, soundFonts: SoundFonts, favorites: Favorites,
       keyboard: Keyboard?, infoBar: InfoBar, settings: Settings) {
    self.viewController = viewController
    self.selectedSoundFontManager = selectedSoundFontManager
    self.activePresetManager = activePresetManager
    self.soundFonts = soundFonts
    self.favorites = favorites
    self.keyboard = keyboard
    self.infoBar = infoBar
    self.settings = settings
    super.init()

    infoBar.addEventClosure(.editVisibility, self.toggleVisibilityEditing)
    infoBar.addEventClosure(.hideMoreButtons) { [weak self] _ in
      guard let self = self, self.view.isEditing else { return }
      self.toggleVisibilityEditing(self)
      self.infoBar.resetButtonState(.editVisibility)
    }

    view.register(TableCell.self)
    view.dataSource = self
    view.delegate = self
    searchBar.delegate = self

    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
    activePresetManager.subscribe(self, notifier: activePresetChange)
    favorites.subscribe(self, notifier: favoritesChange)
    soundFonts.subscribe(self, notifier: soundFontsChange)

    view.sectionIndexColor = .darkGray

    guard let customFont = UIFont(name: "Eurostile", size: 20) else { fatalError("missing Eurostile font") }
    let defaultTextAttributes = [
      NSAttributedString.Key.font: customFont,
      NSAttributedString.Key.foregroundColor: UIColor.systemTeal
    ]
    UITextField.appearance().defaultTextAttributes = defaultTextAttributes

    regenerateViewSlots()
  }
}

extension IndexPath {
  fileprivate init(slotIndex: Int) {
    let section = slotIndex / sectionSize
    self.init(row: slotIndex - section * sectionSize, section: section)
  }

  fileprivate var slotIndex: Int { section * sectionSize + row }
}

extension Array where Element == Slot {
  fileprivate subscript(indexPath: IndexPath) -> Element { self[indexPath.slotIndex] }

  fileprivate func findFavoriteKey(_ key: Favorite.Key) -> Int? {
    for (index, slot) in self.enumerated() {
      if case let .favorite(slotKey) = slot, slotKey == key {
        return index
      }
    }
    return nil
  }

  fileprivate func findPresetIndex(_ presetIndex: Int) -> Int? {
    for (index, slot) in self.enumerated() {
      if case let .preset(slotIndex) = slot, slotIndex == presetIndex {
        return index
      }
    }
    return nil
  }
}

// MARK: - UITableViewDataSource Protocol
extension PresetsTableViewManager: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    showingSearchResults ? 1 : sectionRowCounts.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    searchSlots?.count ?? sectionRowCounts[section]
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    updateCell(cell: tableView.dequeueReusableCell(at: indexPath), at: indexPath)
  }

  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    if showingSearchResults { return nil }
    return [view.isEditing ? "" : UITableView.indexSearch, "•"]
      + stride(from: sectionSize, to: viewSlots.count - 1, by: sectionSize).map { "\($0)" }
  }

  func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
    if index == 0 {
      if !view.isEditing {
        DispatchQueue.main.async { self.showSearchBar() }
      }
      return 0
    }

    return index - 1
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0.0 : 18.0
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "\(section * sectionSize)"
  }
}

// MARK: - UITableViewDelegate Protocol
extension PresetsTableViewManager: UITableViewDelegate {

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    os_log(.debug, log: log, "tableView.didSelectRow")
    if view.isEditing {
      setSlotVisibility(at: indexPath, state: true)
      return
    }

    let slot = getSlot(at: indexPath)
    let wasSearching = dismissSearchResults()

    switch slot {
    case let .preset(presetIndex): selectedPreset(presetIndex, wasSearching: wasSearching)
    case let .favorite(key): selectedFavorite(key, wasSearching: wasSearching)
    }
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    os_log(.debug, log: log, "tableView.didDeselectRow")
    guard view.isEditing else { return }
    setSlotVisibility(at: indexPath, state: false)
  }

  func tableView(_ tableView: UITableView,
                 leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    showingSearchResults ? nil : leadingSwipeActions(at: indexPath)
  }

  func tableView(_ tableView: UITableView,
                 trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    showingSearchResults ? nil : trailingSwipeActions(at: indexPath)
  }

  func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    guard let header = view as? UITableViewHeaderFooterView else { return }
    header.textLabel?.textColor = .systemTeal
    header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    header.backgroundView = UIView()
    header.backgroundView?.backgroundColor = .black
  }
}

extension PresetsTableViewManager: UISearchBarDelegate {

  /**
   Notification from searchBar that the text value changed. NOTE: this is not invoked when programmatically set.

   - parameter searchBar: the UISearchBar where the change took place
   - parameter searchText: the current search term
   */
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    os_log(.debug, log: log, "searchBar.textDidChange - %{public}s", searchText)
    guard let term = searchBar.searchTerm else {
      lastSearchText = ""
      searchSlots = nil
      regenerateViewSlots()
      return
    }

    search(for: term)
  }
}

extension PresetsTableViewManager {

  private func withSoundFont<T>(_ closure: (SoundFont) -> T?) -> T? {
    guard let soundFont = selectedSoundFontManager.selected else { return nil }
    return closure(soundFont)
  }

  private func selectedPreset(_ presetIndex: Int, wasSearching: Bool) {
    withSoundFont { soundFont in
      let soundFontAndPreset = soundFont[presetIndex]
      if !activePresetManager.setActive(preset: soundFontAndPreset, playSample: settings.playSample) {
        if let indexPath = getPresetIndexPath(for: soundFontAndPreset) {
          view.scrollToRow(at: indexPath, at: .none, animated: false)
        }
        hideSearchBar(animated: true)
      }
    }
  }

  private func selectedFavorite(_ key: Favorite.Key, wasSearching: Bool) {
    let favorite = favorites.getBy(key: key)
    if !activePresetManager.setActive(favorite: favorite, playSample: settings.playSample) {
      if let indexPath = getPresetIndexPath(for: key) {
        view.scrollToRow(at: indexPath, at: .none, animated: false)
      }
      hideSearchBar(animated: true)
    }
  }

  private func showSearchBar() {
    guard searchBar.isFirstResponder == false else { return }
    os_log(.info, log: log, "showSearchBar - '%{public}s'", lastSearchText)

    self.searchBar.text = lastSearchText
    searchBar.inputAssistantItem.leadingBarButtonGroups = []
    searchBar.inputAssistantItem.trailingBarButtonGroups = []

    UIView.animate(withDuration: 0.125) {
      self.searchBar.becomeFirstResponder()
      self.view.contentOffset = CGPoint.zero
    } completion: { _ in
      if !self.lastSearchText.isEmpty {
        self.search(for: self.lastSearchText)
      }
    }
  }

  private func dismissSearchKeyboard() {
    guard searchBar.isFirstResponder && searchBar.canResignFirstResponder else { return }
    searchBar.resignFirstResponder()
  }

  /**
   Something has invalidated the viewSlots array. Regenerate it and then reload the table. This will cause the view to
   layout its children, after which it will run the given completion handler.

   - parameter completionHandler: the completion handler to run at end of the table view's layout activity
   */
  private func regenerateViewSlots(_ completionHandler: PresetsTableViewController.OneShotLayoutCompletionHandler? = nil) {
    os_log(.info, log: log, "updateViewPresets")
    let source = selectedSoundFontManager.selected?.presets ?? []

    viewSlots.removeAll()
    for (index, preset) in source.enumerated() {
      if preset.presetConfig.isVisible || view.isEditing {
        viewSlots.append(.preset(index: index))
      }
      for favoriteKey in preset.favorites {
        let favorite = favorites.getBy(key: favoriteKey)
        if favorite.presetConfig.isVisible || view.isEditing {
          viewSlots.append(.favorite(key: favoriteKey))
        }
      }
    }

    calculateSectionRowCounts(reload: false)

    if showingSearchResults, !lastSearchText.isEmpty {
      os_log(.info, log: log, "regenerating search results")
      search(for: lastSearchText)
      return
    }

    viewController.oneShotLayoutCompletionHandler = completionHandler
    os_log(.debug, log: log, "begin reloadData")
    view.reloadData()
    os_log(.debug, log: log, "end reloadData")
  }

  private func calculateSectionRowCounts(reload: Bool) {
    let numFullSections = viewSlots.count / sectionSize
    sectionRowCounts = [Int](repeating: sectionSize, count: numFullSections)
    sectionRowCounts.append(viewSlots.count - numFullSections * sectionSize)
    if reload {
      view.reloadSections(
        IndexSet(stride(from: 0, to: self.sectionRowCounts.count, by: 1)), with: .none)
    }
  }

  private func setSlotVisibility(at indexPath: IndexPath, state: Bool) {
    guard let soundFont = selectedSoundFontManager.selected else { return }
    switch viewSlots[indexPath.slotIndex] {
    case .favorite(let key):
      favorites.setVisibility(key: key, state: state)
    case .preset(let index):
      let soundFontAndPreset = soundFont[index]
      soundFonts.setVisibility(soundFontAndPreset: soundFontAndPreset, state: state)
    }
  }

  private func toggleVisibilityEditing(_ sender: AnyObject) {
    let button = sender as? UIButton
    button?.tintColor = view.isEditing ? .systemTeal : .systemOrange
    if view.isEditing == false {
      _ = dismissSearchResults()
      beginVisibilityEditing()
    } else {
      endVisibilityEditing()
    }
  }

  func performChanges(soundFont: SoundFont) -> [IndexPath] {
    var changes = [IndexPath]()

    func processPresetConfig(_ slotIndex: Int, presetConfig: PresetConfig, slot: () -> Slot) {
      guard presetConfig.isVisible == false else { return }
      let indexPath = IndexPath(slotIndex: slotIndex)
      if view.isEditing {
        os_log(.info, log: log, "slot %d showing - '%{public}s'", slotIndex, presetConfig.name)
        viewSlots.insert(slot(), at: slotIndex)
        changes.append(indexPath)
        sectionRowCounts[indexPath.section] += 1
      } else {
        os_log(.info, log: log, "slot %d hiding - '%{public}s'", slotIndex, presetConfig.name)
        viewSlots.remove(at: slotIndex - changes.count)
        changes.append(indexPath)
        sectionRowCounts[indexPath.section] -= 1
      }
    }

    var slotIndex = 0
    for (presetIndex, preset) in soundFont.presets.enumerated() {
      processPresetConfig(slotIndex, presetConfig: preset.presetConfig) {
        .preset(index: presetIndex)
      }
      slotIndex += 1
      for favoriteKey in preset.favorites {
        let favorite = favorites.getBy(key: favoriteKey)
        processPresetConfig(slotIndex, presetConfig: favorite.presetConfig) {
          .favorite(key: favoriteKey)
        }
        slotIndex += 1
      }
    }

    return changes
  }

  private func beginVisibilityEditing() {
    withSoundFont { soundFont in
      self.calculateSectionRowCounts(reload: true)
      view.setEditing(true, animated: true)
      let changes = performChanges(soundFont: soundFont)
      os_log(.info, log: log, "beginVisibilityEditing - %d changes", changes.count)

      view.performBatchUpdates {
        view.insertRows(at: changes, with: .automatic)
      } completion: { _ in
        self.initializeVisibilitySelections(soundFont: soundFont)
      }
    }
  }

  private func endVisibilityEditing() {
    withSoundFont { soundFont in
      CATransaction.begin()
      CATransaction.setCompletionBlock {
        self.calculateSectionRowCounts(reload: true)
      }
      view.setEditing(false, animated: true)

      let changes = performChanges(soundFont: soundFont)
      os_log(.info, log: log, "endVisibilityEditing - %d changes", changes.count)

      view.performBatchUpdates {
        view.deleteRows(at: changes, with: .automatic)
      } completion: { _ in
        self.infoBar.hideMoreButtons()
      }

      CATransaction.commit()
    }
  }

  private func presetConfigForSlot(_ slot: Slot) -> PresetConfig? {
    return withSoundFont { soundFont in
      switch slot {
      case .favorite(let key): return favorites.getBy(key: key).presetConfig
      case .preset(let presetIndex): return soundFont.presets[presetIndex].presetConfig
      }
    }
  }

  private func initializeVisibilitySelections(soundFont: SoundFont) {
    precondition(view.isEditing)
    os_log(.debug, log: self.log, "initializeVisibilitySelections")
    for (slotIndex, slot) in viewSlots.enumerated() {
      let indexPath = IndexPath(slotIndex: slotIndex)
      guard let presetConfig = presetConfigForSlot(slot) else { continue }
      if presetConfig.isVisible {
        view.selectRow(at: indexPath, animated: false, scrollPosition: .none)
      }
    }
  }

  private func activePresetChange(_ event: ActivePresetEvent) {
    switch event {
    case let .active(old: old, new: new, playSample: _):
      os_log(.debug, log: log, "activePresetChange")

      // Update the two rows involved in the change in active preset
      view.performBatchUpdates(
        {
          updateRow(with: old)
          updateRow(with: new)
        },
        completion: { _ in

          // Now that row cells have updated, make sure that the new one is visible.
          guard let indexPath = self.getPresetIndexPath(for: new) else { return }
          self.view.scrollToRow(at: indexPath, at: .none, animated: false)

          // Finally, on the next view update, make sure that the search bar is no longer visible.
          DispatchQueue.main.async {
            self.hideSearchBar(animated: true)
          }
        })
    }
  }

  private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
    guard case let .changed(old: old, new: new) = event else { return }
    os_log(.debug, log: log, "selectedSoundFontChange - old: '%{public}s' new: '%{public}s'",
           old?.displayName ?? "N/A", new?.displayName ?? "N/A")

    let animateHideSearchBar = searchBarIsVisible
    let oneShotLayoutCompletionHandler: PresetsTableViewController.OneShotLayoutCompletionHandler? = {
      if view.isEditing {
        if let soundFont = new {
          return { self.initializeVisibilitySelections(soundFont: soundFont) }
        }
      }
      else {
        if activePresetManager.activeSoundFont == new {
          return { self.selectActive(animated: false) }
        } else if !showingSearchResults {
          return { self.hideSearchBar(animated: animateHideSearchBar) }
        }
      }
      return nil
    }()

    regenerateViewSlots(oneShotLayoutCompletionHandler)
  }

  private func favoritesChange(_ event: FavoritesEvent) {
    os_log(.debug, log: log, "favoritesChange")
    switch event {
    case .restored:
      os_log(.info, log: log, "favoritesChange - restored")
      favoritesRestored()

    case let .added(_, favorite):
      os_log(.info, log: log, "favoritesChange - added - %{public}s", favorite.key.uuidString)

    case let .removed(_, favorite):
      os_log(.info, log: log, "favoritesChange - removed - %{public}s", favorite.key.uuidString)

    case let .changed(_, favorite):
      os_log(.info, log: log, "favoritesChange - changed - %{public}s", favorite.key.uuidString)
      updateRow(with: favorite)

    case .selected: break
    case .beginEdit: break
    case .removedAll: break
    }
  }

  private func favoritesRestored() {
    if let visibleRows = view.indexPathsForVisibleRows {
      view.reloadRows(at: visibleRows, with: .automatic)
    } else {
      view.reloadData()
    }
  }

  private func soundFontsChange(_ event: SoundFontsEvent) {
    switch event {
    case let .unhidPresets(font: soundFont):
      if soundFont == selectedSoundFontManager.selected {
        regenerateViewSlots()
      }

    case let .presetChanged(soundFont, index):
      if soundFont == selectedSoundFontManager.selected {
        let soundFontAndPreset = soundFont[index]
        updateRow(with: soundFontAndPreset)
      }

    case .restored: soundFontsRestored()
    case .added: break
    case .moved: break
    case .removed: break
    }
  }

  private func soundFontsRestored() {
    let animateHideSearchBar = searchBarIsVisible
    regenerateViewSlots {
      self.selectActive(animated: false)
      self.hideSearchBar(animated: animateHideSearchBar)
    }
  }

  private func getPresetIndexPath(for key: Favorite.Key) -> IndexPath? {
    guard favorites.contains(key: key) else { return nil }
    if showingSearchResults {
      guard let row = searchSlots?.findFavoriteKey(key) else { return nil }
      return IndexPath(row: row, section: 0)
    }

    guard let index = viewSlots.findFavoriteKey(key) else { return nil }
    return IndexPath(slotIndex: index)
  }

  private func getPresetIndexPath(for soundFontAndPreset: SoundFontAndPreset?) -> IndexPath? {
    guard let soundFontAndPreset = soundFontAndPreset,
          let soundFont = selectedSoundFontManager.selected,
          soundFont.key == soundFontAndPreset.soundFontKey else {
      return nil
    }

    let presetIndex = soundFontAndPreset.presetIndex
    if showingSearchResults {
      guard let row = searchSlots?.findPresetIndex(presetIndex) else { return nil }
      return IndexPath(row: row, section: 0)
    }

    guard let index = viewSlots.findPresetIndex(presetIndex) else { return nil }
    return IndexPath(slotIndex: index)
  }

  private func dismissSearchResults() -> Bool {
    guard searchBar.searchTerm != nil else { return false }
    os_log(.debug, log: log, "dismissSearchResults")
    searchBar.text = nil
    searchSlots = nil
    view.reloadData()
    dismissSearchKeyboard()
    return true
  }

  private func search(for searchTerm: String) {
    os_log(.debug, log: log, "search - '%{public}s'", searchTerm)
    lastSearchText = searchTerm
    withSoundFont { soundFont in
      searchSlots = viewSlots.filter { slot in
        let name: String = {
          switch slot {
          case .favorite(let key): return favorites.getBy(key: key).presetConfig.name
          case .preset(let presetIndex): return soundFont.presets[presetIndex].presetConfig.name
          }
        }()
        return name.localizedCaseInsensitiveContains(searchTerm)
      }
    }
    os_log(.debug, log: log, "found %d matches", searchSlots?.count ?? 0)

    view.reloadData()
  }

  public var searchBarIsVisible: Bool { view.contentOffset.y < searchBar.frame.size.height }

  public func hideSearchBar(animated: Bool) {
    dismissSearchKeyboard()

    if showingSearchResults || view.contentOffset.y > searchBar.frame.size.height * 2 { return }
    os_log(.info, log: log, "hiding search bar - %d", animated)

    let view = self.view
    let contentOffset = CGPoint(x: 0, y: searchBar.frame.size.height)
    if animated {
      UIViewPropertyAnimator.runningPropertyAnimator(
        withDuration: 0.3, delay: 0.0, options: [.curveEaseOut],
        animations: { view.contentOffset = contentOffset },
        completion: { _ in view.contentOffset = contentOffset })
    } else {
      view.contentOffset = contentOffset
    }
  }

  func selectActive(animated: Bool) {
    os_log(.debug, log: log, "selectActive - %d", animated)
    guard let activeSlot: Slot = {
      switch activePresetManager.active {
      case let .preset(soundFontAndPreset): return .preset(index: soundFontAndPreset.presetIndex)
      case let .favorite(favorite): return .favorite(key: favorite.key)
      case .none: return nil
      }
    }()
    else { return }

    guard let slotIndex = (viewSlots.firstIndex { $0 == activeSlot }) else { return }
    let indexPath = IndexPath(slotIndex: slotIndex)
    view.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
    hideSearchBar(animated: animated)
  }

  private func isActive(_ soundFontAndPreset: SoundFontAndPreset) -> Bool {
    activePresetManager.active.soundFontAndPreset == soundFontAndPreset
  }
}

// MARK: - Swipe Actions

extension PresetsTableViewManager {

  private func leadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
    let slot = getSlot(at: indexPath)
    let actions: [UIContextualAction] = {
      switch slot {
      case .preset:
        guard let soundFontAndPreset = makeSoundFontAndPreset(at: indexPath) else { return [] }
        return [
          editPresetSwipeAction(at: indexPath, cell: cell, soundFontAndPreset: soundFontAndPreset),
          createFavoriteSwipeAction(at: indexPath, cell: cell, soundFontAndPreset: soundFontAndPreset)
        ]
      case .favorite:
        return [
          editFavoriteSwipeAction(at: indexPath)
        ]
      }
    }()
    return makeSwipeActionConfiguration(actions: actions)
  }

  private func editPresetSwipeAction(at indexPath: IndexPath, cell: TableCell,
                                     soundFontAndPreset: SoundFontAndPreset) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemTeal) { [weak self] _, view, completionHandler in
      guard let self = self else { return }
      var rect = self.view.rectForRow(at: indexPath)
      rect.size.width = 240.0
      self.favorites.beginEdit(
        config: FavoriteEditor.Config.preset(
          state: FavoriteEditor.State(
            indexPath: indexPath, sourceView: view, sourceRect: view.bounds,
            currentLowestNote: self.keyboard?.lowestNote,
            completionHandler: completionHandler, soundFonts: self.soundFonts,
            soundFontAndPreset: soundFontAndPreset,
            settings: self.settings))
      )
    }
  }

  private func createFavoriteSwipeAction(at indexPath: IndexPath, cell: TableCell,
                                         soundFontAndPreset: SoundFontAndPreset) -> UIContextualAction {
    UIContextualAction(icon: .favorite, color: .systemOrange) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      completionHandler(self.createFavorite(at: indexPath, with: soundFontAndPreset))
    }
  }

  private func createFavorite(at indexPath: IndexPath, with soundFontAndPreset: SoundFontAndPreset) -> Bool
  {
    guard let soundFont = self.soundFonts.getBy(key: soundFontAndPreset.soundFontKey) else { return false }
    let preset = soundFont.presets[soundFontAndPreset.presetIndex]
    guard let favorite = soundFonts.createFavorite(soundFontAndPreset: soundFontAndPreset,
                                                   keyboardLowestNote: keyboard?.lowestNote) else { return false }
    favorites.add(favorite: favorite)
    let favoriteIndex = IndexPath(slotIndex: indexPath.slotIndex + preset.favorites.count)

    view.performBatchUpdates {
      viewSlots.insert(.favorite(key: favorite.key), at: favoriteIndex.slotIndex)
      view.insertRows(at: [favoriteIndex], with: .automatic)
      sectionRowCounts[favoriteIndex.section] += 1
    } completion: { _ in
      self.calculateSectionRowCounts(reload: true)
    }

    return true
  }

  private func deleteFavoriteSwipeAction(at indexPath: IndexPath, cell: TableCell) -> UIContextualAction {
    UIContextualAction(icon: .unfavorite, color: .systemRed) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      completionHandler(self.deleteFavorite(at: indexPath, cell: cell))
    }
  }

  private func deleteFavorite(at indexPath: IndexPath, cell: TableCell) -> Bool {
    guard case let .favorite(key) = getSlot(at: indexPath) else { fatalError("unexpected slot type") }
    let favorite = favorites.getBy(key: key)
    favorites.remove(key: key)
    soundFonts.deleteFavorite(soundFontAndPreset: favorite.soundFontAndPreset, key: favorite.key)
    view.performBatchUpdates {
      viewSlots.remove(at: indexPath.slotIndex)
      view.deleteRows(at: [indexPath], with: .automatic)
      sectionRowCounts[indexPath.section] -= 1
    } completion: { _ in
      self.calculateSectionRowCounts(reload: true)
      if favorite == self.activePresetManager.activeFavorite {
        self.activePresetManager.setActive(preset: favorite.soundFontAndPreset, playSample: false)
      }
    }

    return true
  }

  private func editFavoriteSwipeAction(at indexPath: IndexPath) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemOrange) { [weak self] _, _, completionHandler in
      self?.editFavorite(at: indexPath, completionHandler: completionHandler)
    }
  }

  private func editFavorite(at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
    guard case let .favorite(key) = getSlot(at: indexPath) else { fatalError("unexpected nil") }
    let favorite = favorites.getBy(key: key)
    let position = favorites.index(of: favorite.key)
    var rect = view.rectForRow(at: indexPath)
    rect.size.width = 240.0
    let configState = FavoriteEditor.State(
      indexPath: IndexPath(item: position, section: 0),
      sourceView: view, sourceRect: view.bounds,
      currentLowestNote: self.keyboard?.lowestNote,
      completionHandler: completionHandler, soundFonts: self.soundFonts,
      soundFontAndPreset: favorite.soundFontAndPreset,
      settings: settings)
    let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
    self.favorites.beginEdit(config: config)
  }

  private func trailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
    guard let soundFontAndPreset = makeSoundFontAndPreset(at: indexPath) else { return nil }
    let slot = getSlot(at: indexPath)
    let actions: [UIContextualAction] = {
      switch slot {
      case .preset:
        return [
          createHideSwipeAction(at: indexPath, cell: cell, soundFontAndPreset: soundFontAndPreset)
        ]
      case .favorite:
        return [deleteFavoriteSwipeAction(at: indexPath, cell: cell)]
      }
    }()
    return makeSwipeActionConfiguration(actions: actions)
  }

  private func createHideSwipeAction(at indexPath: IndexPath, cell: TableCell,
                                     soundFontAndPreset: SoundFontAndPreset) -> UIContextualAction {
    UIContextualAction(icon: .hide, color: .gray) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      if self.settings.showedHidePresetPrompt {
        self.hidePreset(soundFontAndPreset: soundFontAndPreset, indexPath: indexPath,
                        completionHandler: completionHandler)
      } else {
        self.promptToHidePreset(soundFontAndPreset: soundFontAndPreset, indexPath: indexPath,
                                completionHandler: completionHandler)
      }
    }
  }

  private func makeSwipeActionConfiguration(actions: [UIContextualAction]) -> UISwipeActionsConfiguration {
    let actions = UISwipeActionsConfiguration(actions: actions)
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }

  private func hidePreset(soundFontAndPreset: SoundFontAndPreset, indexPath: IndexPath,
                          completionHandler: (Bool) -> Void) {
    self.soundFonts.setVisibility(soundFontAndPreset: soundFontAndPreset, state: false)
    self.viewSlots.remove(at: indexPath.slotIndex)
    self.view.performBatchUpdates({
      self.view.deleteRows(at: [indexPath], with: .automatic)
      self.sectionRowCounts[indexPath.section] -= 1
    },
    completion: { _ in
      self.calculateSectionRowCounts(reload: true)
    })
    completionHandler(true)
  }

  private func promptToHidePreset(soundFontAndPreset: SoundFontAndPreset, indexPath: IndexPath,
                                  completionHandler: @escaping (Bool) -> Void) {
    let promptTitle = Formatters.strings.hidePresetTitle
    let promptMessage = Formatters.strings.hidePresetMessage
    let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)
    let hide = UIAlertAction(title: Formatters.strings.hidePresetAction, style: .default) { [weak self] _ in
      guard let self = self else { return }
      self.settings.showedHidePresetPrompt = true
      self.hidePreset(soundFontAndPreset: soundFontAndPreset, indexPath: indexPath,
                      completionHandler: completionHandler)
    }

    let cancel = UIAlertAction(title: Formatters.strings.cancelAction, style: .cancel) { _ in
      completionHandler(false)
    }

    alertController.addAction(hide)
    alertController.addAction(cancel)

    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    viewController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: - Updates

extension PresetsTableViewManager {

  private func getSlot(at indexPath: IndexPath) -> Slot {
    os_log(.debug, log: log, "getSlot BEGIN: %d %d %d", indexPath.row, searchSlots?.count ?? 0, viewSlots.count)
    return searchSlots?[indexPath] ?? viewSlots[indexPath]
  }

  private func makeSoundFontAndPreset(at indexPath: IndexPath) -> SoundFontAndPreset? {
    guard let soundFont = selectedSoundFontManager.selected else { return nil }
    let presetIndex: Int = {
      switch getSlot(at: indexPath) {
      case .favorite(let key): return favorites.getBy(key: key).soundFontAndPreset.presetIndex
      case .preset(let presetIndex): return presetIndex
      }
    }()
    return soundFont[presetIndex]
  }

  private func updateRow(with activeKind: ActivePresetKind?) {
    os_log(.debug, log: log, "updateRow - with activeKind")
    guard let activeKind = activeKind else { return }
    switch activeKind {
    case .none: return
    case .preset(let soundFontAndPreset): updateRow(with: soundFontAndPreset)
    case .favorite(let favorite): updateRow(with: favorite)
    }
  }

  private func updateRow(with favorite: Favorite) {
    os_log(.debug, log: log, "updateRow - with favorite")
    guard let indexPath = getPresetIndexPath(for: favorite.key),
          let cell: TableCell = view.cellForRow(at: indexPath)
    else { return }
    updateCell(cell: cell, at: indexPath)
  }

  private func updateRow(with soundFontAndPreset: SoundFontAndPreset?) {
    os_log(.debug, log: log, "updateRow - with soundFontAndPreset")
    guard let indexPath = getPresetIndexPath(for: soundFontAndPreset),
          let cell: TableCell = view.cellForRow(at: indexPath)
    else { return }
    updateCell(cell: cell, at: indexPath)
  }

  private func getPresetIndexPath(for activeKind: ActivePresetKind) -> IndexPath? {
    switch activeKind {
    case .none: return nil
    case .preset(let soundFontAndPreset): return getPresetIndexPath(for: soundFontAndPreset)
    case .favorite(let favorite): return getPresetIndexPath(for: favorite.key)
    }
  }

  @discardableResult
  private func updateCell(cell: TableCell, at indexPath: IndexPath) -> TableCell {
    guard let soundFont = selectedSoundFontManager.selected else {
      os_log(.error, log: log, "unexpected nil soundFont")
      return cell
    }

    switch getSlot(at: indexPath) {
    case let .preset(presetIndex):
      let soundFontAndPreset = soundFont[presetIndex]
      let preset = soundFont.presets[presetIndex]
      os_log(.debug, log: log, "updateCell - preset '%{public}s' %d in row %d section %d",
             preset.presetConfig.name, presetIndex, indexPath.row, indexPath.section)
      cell.updateForPreset(name: preset.presetConfig.name,
                           isActive: soundFontAndPreset == activePresetManager.active.soundFontAndPreset
                                && activePresetManager.activeFavorite == nil)
    case let .favorite(key):
      let favorite = favorites.getBy(key: key)
      os_log(.debug, log: log, "updateCell - favorite '%{public}s' in row %d section %d",
             favorite.presetConfig.name, indexPath.row, indexPath.section)
      cell.updateForFavorite(name: favorite.presetConfig.name,
                             isActive: activePresetManager.activeFavorite == favorite)
    }
    return cell
  }
}
