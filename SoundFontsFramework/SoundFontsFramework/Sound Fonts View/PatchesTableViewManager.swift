// Copyright © 2018 Brad Howes. All rights reserved.
import UIKit
import os

/// Number of sections we partition patches into
private let sectionSize = 20

private enum Slot: Equatable {
  case preset(index: Int)
  case favorite(key: LegacyFavorite.Key)
}

/// Data source and delegate for the Patches UITableView. This is one of the most complicated managers and it should be
/// broken up into smaller components.
final class PatchesTableViewManager: NSObject {

  private lazy var log = Logging.logger("PatchesTableViewManager")

  private weak var viewController: UIViewController?
  private let view: PatchesTableView

  private let searchBar: UISearchBar
  private var lastSearchText: String?
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePatchManager: ActivePatchManager
  private let soundFonts: SoundFonts
  private let favorites: Favorites
  private let keyboard: Keyboard?
  private let infoBar: InfoBar

  private var viewSlots = [Slot]()
  private var searchSlots = [Slot]()
  private var sectionRowCounts = [Int]()

  private var notificationObserver: NSObjectProtocol?
  private var contentSizeObserver: NSKeyValueObservation?

  /**
     Construct a new patches table view manager.

     - parameter view: the view to manage
     - parameter searchBar: the search bar that filters on preset name
     - parameter activePatchManager: the active preset manager
     - parameter selectedSoundFontManager: the selected sound font manager
     - parameter soundFonts: the sound fonts collection manager
     - parameter favorites: the favorites collection manager
     - parameter keyboard: the optional keyboard view manager
     - parameter infoBar: the info bar manager
     */
  init(
    viewController: UIViewController, view: PatchesTableView, searchBar: UISearchBar,
    activePatchManager: ActivePatchManager, selectedSoundFontManager: SelectedSoundFontManager,
    soundFonts: SoundFonts, favorites: Favorites, keyboard: Keyboard?, infoBar: InfoBar
  ) {
    self.viewController = viewController
    self.view = view
    self.searchBar = searchBar
    searchBar.text = nil
    self.selectedSoundFontManager = selectedSoundFontManager
    self.activePatchManager = activePatchManager
    self.soundFonts = soundFonts
    self.favorites = favorites
    self.keyboard = keyboard
    self.infoBar = infoBar
    super.init()

    // When there is a change in size, hide the search bar if it is not in use.
    contentSizeObserver = self.view.observe(\.contentSize, options: [.old, .new]) { tableView, change in
      guard let oldValue = change.oldValue, let newValue = change.newValue, oldValue != newValue
      else { return }
      if !self.searchBar.isFirstResponder && tableView.contentOffset.y < searchBar.frame.size.height
      {
        tableView.contentOffset = CGPoint(x: 0, y: self.searchBar.frame.size.height)
      }
    }

    infoBar.addEventClosure(.editVisibility, self.toggleVisibilityEditing)

    view.register(TableCell.self)
    view.dataSource = self
    view.delegate = self
    searchBar.delegate = self

    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
    activePatchManager.subscribe(self, notifier: activePatchChange)
    favorites.subscribe(self, notifier: favoritesChange)
    soundFonts.subscribe(self, notifier: soundFontsChange)

    view.sectionIndexColor = .darkGray

    let customFont = UIFont(name: "Eurostile", size: 20)!
    let defaultTextAttributes = [
      NSAttributedString.Key.font: customFont,
      NSAttributedString.Key.foregroundColor: UIColor.systemTeal
    ]
    UITextField.appearance().defaultTextAttributes = defaultTextAttributes

    updateViewPresets()
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
}

extension Array where Element == Slot {
  fileprivate func findFavoriteKey(_ key: LegacyFavorite.Key) -> Int? {
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
extension PatchesTableViewManager: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    showingSearchResults ? 1 : sectionRowCounts.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    showingSearchResults ? searchSlots.count : sectionRowCounts[section]
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    updateCell(cell: tableView.dequeueReusableCell(at: indexPath), at: indexPath)
  }

  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    if showingSearchResults { return nil }
    return [view.isEditing ? "" : UITableView.indexSearch, "•"]
      + stride(
        from: sectionSize, to: viewSlots.count - 1,
        by: sectionSize
      ).map { "\($0)" }
  }

  func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int)
    -> Int
  {
    if index == 0 {
      if !view.isEditing {
        DispatchQueue.main.async { self.showSearchBar() }
      }
      return 0
    }

    dismissSearchKeyboard()
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
extension PatchesTableViewManager: UITableViewDelegate {

  func tableView(
    _ tableView: UITableView,
    editingStyleForRowAt indexPath: IndexPath
  ) -> UITableViewCell.EditingStyle {
    .none
  }

  // func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if view.isEditing {
      setSlotVisibility(at: indexPath, state: true)
      return
    }

    let slot = getSlot(at: indexPath)
    dismissSearchResults()

    switch slot {
    case let .preset(presetIndex): selectPreset(presetIndex)
    case let .favorite(key):
      activePatchManager.setActive(
        favorite: favorites.getBy(key: key),
        playSample: Settings.shared.playSample)
    }
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    guard view.isEditing else { return }
    setSlotVisibility(at: indexPath, state: false)
  }

  func tableView(
    _ tableView: UITableView,
    leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    showingSearchResults ? nil : leadingSwipeActions(at: indexPath)
  }

  func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    showingSearchResults ? nil : trailingSwipeActions(at: indexPath)
  }

  func tableView(
    _ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int
  ) {
    guard let header = view as? UITableViewHeaderFooterView else { return }
    header.textLabel?.textColor = .systemTeal
    header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
    header.backgroundView = UIView()
    header.backgroundView?.backgroundColor = .black
  }
}

extension PatchesTableViewManager: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    search(for: searchBar.searchTerm ?? "")
  }
}

extension PatchesTableViewManager {

  private func withSoundFont<T>(_ closure: (LegacySoundFont) -> T?) -> T? {
    guard let soundFont = selectedSoundFontManager.selected else { return nil }
    return closure(soundFont)
  }

  private func selectPreset(_ presetIndex: Int) {
    withSoundFont { soundFont in
      let soundFontAndPatch = SoundFontAndPatch(
        soundFontKey: soundFont.key, patchIndex: presetIndex)
      activePatchManager.setActive(
        preset: soundFontAndPatch, playSample: Settings.shared.playSample)
    }
  }

  private func showSearchBar() {
    guard searchBar.isFirstResponder == false else { return }

    searchBar.inputAssistantItem.leadingBarButtonGroups = []
    searchBar.inputAssistantItem.trailingBarButtonGroups = []
    UIView.animate(withDuration: 0.25) {
      self.searchBar.becomeFirstResponder()
      self.view.contentOffset = CGPoint.zero
    } completion: { _ in
      if let term = self.lastSearchText, !term.isEmpty {
        self.searchBar.text = term
        self.search(for: term)
      }
    }
  }

  private func dismissSearchKeyboard() {
    guard searchBar.isFirstResponder && searchBar.canResignFirstResponder else { return }
    searchBar.resignFirstResponder()
  }

  private func updateViewPresets(_ completionHandler: PatchesTableView.OneShotLayoutCompletionHandler? = nil) {
    let source = selectedSoundFontManager.selected?.patches ?? []
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

    updateSectionRowCounts(reload: false)
    view.oneShotLayoutCompletionHandler = completionHandler
    view.reloadData()
  }

  private func updateSectionRowCounts(reload: Bool) {
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
      let soundFontAndPatch = SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: index)
      soundFonts.setVisibility(soundFontAndPatch: soundFontAndPatch, state: state)
    }
  }

  private func toggleVisibilityEditing(_ sender: AnyObject) {
    let button = sender as? UIButton
    button?.tintColor = view.isEditing ? .systemTeal : .systemOrange
    if view.isEditing == false {
      dismissSearchResults()
      beginVisibilityEditing()
    } else {
      endVisibilityEditing()
    }
  }

  func performChanges(soundFont: LegacySoundFont) -> [IndexPath] {
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
    for (presetIndex, preset) in soundFont.patches.enumerated() {
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
      self.updateSectionRowCounts(reload: true)
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
        self.updateSectionRowCounts(reload: true)
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
      case .preset(let presetIndex): return soundFont.patches[presetIndex].presetConfig
      }
    }
  }

  private func initializeVisibilitySelections(soundFont: LegacySoundFont) {
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

  private func activePatchChange(_ event: ActivePatchEvent) {
    switch event {
    case let .active(old: old, new: new, playSample: _):
      os_log(.debug, log: log, "activePatchChange")

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

    let oneShotLayoutCompletionHandler: PatchesTableView.OneShotLayoutCompletionHandler? = {
      if view.isEditing {
        if let soundFont = new {
          return { self.initializeVisibilitySelections(soundFont: soundFont) }
        }
      }
      else {
        if activePatchManager.activeSoundFont == new {
          return { self.selectActive(animated: false) }
        } else if !showingSearchResults {
          return { self.hideSearchBar(animated: false) }
        }
      }
      return nil
    }()

    updateViewPresets(oneShotLayoutCompletionHandler)
  }

  private func favoritesRestored() {
    if let visibleRows = view.indexPathsForVisibleRows {
      view.reloadRows(at: visibleRows, with: .automatic)
    } else {
      view.reloadData()
    }
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

  private func soundFontsRestored() {
    updateViewPresets {
      self.selectActive(animated: false)
      self.hideSearchBar(animated: false)
    }
  }

  private func soundFontsChange(_ event: SoundFontsEvent) {
    switch event {
    case let .unhidPresets(font: soundFont):
      if soundFont == selectedSoundFontManager.selected {
        updateViewPresets()
      }

    case let .presetChanged(soundFont, index):
      if soundFont == selectedSoundFontManager.selected {
        let soundFontAndPatch = soundFont.makeSoundFontAndPatch(at: index)
        updateRow(with: soundFontAndPatch)
      }

    case .restored:
      if viewSlots.isEmpty {
        soundFontsRestored()
      }
    case .added: break
    case .moved: break
    case .removed: break
    }
  }

  private func getPresetIndexPath(for key: LegacyFavorite.Key) -> IndexPath? {
    guard favorites.contains(key: key) else { return nil }
    if showingSearchResults {
      guard let row = searchSlots.findFavoriteKey(key) else { return nil }
      return IndexPath(row: row, section: 0)
    }

    guard let index = viewSlots.findFavoriteKey(key) else { return nil }
    return IndexPath(slotIndex: index)
  }

  private func getPresetIndexPath(for soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
    guard let soundFontAndPatch = soundFontAndPatch else { return nil }
    guard let soundFont = selectedSoundFontManager.selected,
      soundFont.key == soundFontAndPatch.soundFontKey
    else { return nil }
    let presetIndex = soundFontAndPatch.patchIndex
    if showingSearchResults {
      guard let row = searchSlots.findPresetIndex(presetIndex) else { return nil }
      return IndexPath(row: row, section: 0)
    }

    guard let index = viewSlots.findPresetIndex(presetIndex) else { return nil }
    return IndexPath(slotIndex: index)
  }

  private var showingSearchResults: Bool { searchBar.searchTerm != nil }

  private func dismissSearchResults() {
    guard searchBar.searchTerm != nil else { return }
    os_log(.debug, log: log, "dismissSearchResults")
    searchBar.text = nil
    searchSlots.removeAll()
    view.reloadData()
    dismissSearchKeyboard()
  }

  private func search(for searchTerm: String) {
    os_log(.debug, log: log, "search - '%{public}s'", searchTerm)
    lastSearchText = searchTerm
    withSoundFont { soundFont in
      searchSlots = viewSlots.filter { slot in
        let name: String = {
          switch slot {
          case .favorite(let key): return favorites.getBy(key: key).presetConfig.name
          case .preset(let presetIndex): return soundFont.patches[presetIndex].presetConfig.name
          }
        }()
        return name.localizedCaseInsensitiveContains(searchTerm)
      }
    }
    os_log(.debug, log: log, "found %d matches", searchSlots.count)
    view.reloadData()
  }

  private func hideSearchBar(animated: Bool) {
    dismissSearchKeyboard()
    if showingSearchResults || view.contentOffset.y > searchBar.frame.size.height * 2 { return }
    os_log(.info, log: log, "hiding search bar")
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
    os_log(.debug, log: log, "selectActive")
    guard
      let activeSlot: Slot = {
        switch activePatchManager.active {
        case let .preset(soundFontAndPatch): return .preset(index: soundFontAndPatch.patchIndex)
        case let .favorite(favorite): return .favorite(key: favorite.key)
        case .none: return nil
        }
      }()
    else { return }

    guard let slotIndex = (viewSlots.firstIndex { $0 == activeSlot }) else { return }
    let indexPath = IndexPath(slotIndex: slotIndex)
    let visibleRows = view.indexPathsForVisibleRows
    if !(visibleRows?.contains(indexPath) ?? false) {
      os_log(.debug, log: log, "scrolling to selected row")
      view.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
    }
    hideSearchBar(animated: true)
  }

  private func isActive(_ soundFontAndPatch: SoundFontAndPatch) -> Bool {
    activePatchManager.active.soundFontAndPatch == soundFontAndPatch
  }
}

// MARK: - Swipe Actions

extension PatchesTableViewManager {

  private func leadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
    let slot = getSlot(at: indexPath)
    let actions: [UIContextualAction] = {
      switch slot {
      case .preset:
        guard let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath) else { return [] }
        return [
          editPresetSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch),
          createFavoriteSwipeAction(
            at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch)
        ]
      case .favorite:
        return [
          editFavoriteSwipeAction(at: indexPath)
        ]
      }
    }()
    return makeSwipeActionConfiguration(actions: actions)
  }

  private func editPresetSwipeAction(
    at indexPath: IndexPath, cell: TableCell,
    soundFontAndPatch: SoundFontAndPatch
  ) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemTeal) { _, view, completionHandler in
      var rect = self.view.rectForRow(at: indexPath)
      rect.size.width = 240.0
      self.favorites.beginEdit(
        config: FavoriteEditor.Config.preset(
          state: FavoriteEditor.State(
            indexPath: indexPath, sourceView: view, sourceRect: view.bounds,
            currentLowestNote: self.keyboard?.lowestNote,
            completionHandler: completionHandler, soundFonts: self.soundFonts,
            soundFontAndPatch: soundFontAndPatch))
      )
    }
  }

  private func createFavoriteSwipeAction(
    at indexPath: IndexPath, cell: TableCell,
    soundFontAndPatch: SoundFontAndPatch
  ) -> UIContextualAction {
    UIContextualAction(icon: .favorite, color: .systemOrange) { _, _, completionHandler in
      completionHandler(self.createFavorite(at: indexPath, with: soundFontAndPatch))
    }
  }

  private func createFavorite(at indexPath: IndexPath, with soundFontAndPatch: SoundFontAndPatch)
    -> Bool
  {
    guard let soundFont = self.soundFonts.getBy(key: soundFontAndPatch.soundFontKey) else {
      return false
    }
    let preset = soundFont.patches[soundFontAndPatch.patchIndex]
    guard
      let favorite = soundFonts.createFavorite(
        soundFontAndPatch: soundFontAndPatch,
        keyboardLowestNote: keyboard?.lowestNote)
    else { return false }
    favorites.add(favorite: favorite)
    let favoriteIndex = IndexPath(slotIndex: indexPath.slotIndex + preset.favorites.count)

    view.performBatchUpdates {
      viewSlots.insert(.favorite(key: favorite.key), at: favoriteIndex.slotIndex)
      view.insertRows(at: [favoriteIndex], with: .automatic)
      sectionRowCounts[favoriteIndex.section] += 1
    } completion: { _ in
      self.updateSectionRowCounts(reload: true)
    }

    return true
  }

  private func deleteFavoriteSwipeAction(at indexPath: IndexPath, cell: TableCell)
    -> UIContextualAction
  {
    UIContextualAction(icon: .unfavorite, color: .systemRed) { _, _, completionHandler in
      completionHandler(self.deleteFavorite(at: indexPath, cell: cell))
    }
  }

  private func deleteFavorite(at indexPath: IndexPath, cell: TableCell) -> Bool {
    guard case let .favorite(key) = getSlot(at: indexPath) else {
      fatalError("unexpected slot type")
    }
    let favorite = favorites.getBy(key: key)
    favorites.remove(key: key)
    soundFonts.deleteFavorite(soundFontAndPatch: favorite.soundFontAndPatch, key: favorite.key)
    view.performBatchUpdates {
      viewSlots.remove(at: indexPath.slotIndex)
      view.deleteRows(at: [indexPath], with: .automatic)
      sectionRowCounts[indexPath.section] -= 1
    } completion: { _ in
      self.updateSectionRowCounts(reload: true)
      if favorite == self.activePatchManager.activeFavorite {
        self.activePatchManager.setActive(preset: favorite.soundFontAndPatch, playSample: false)
      }
    }

    return true
  }

  private func editFavoriteSwipeAction(at indexPath: IndexPath) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemOrange) { _, _, completionHandler in
      self.editFavorite(at: indexPath, completionHandler: completionHandler)
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
      soundFontAndPatch: favorite.soundFontAndPatch)
    let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
    self.favorites.beginEdit(config: config)
  }

  private func trailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
    guard let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath) else { return nil }
    let slot = getSlot(at: indexPath)
    let actions: [UIContextualAction] = {
      switch slot {
      case .preset:
        return [
          createHideSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch)
        ]
      case .favorite:
        return [deleteFavoriteSwipeAction(at: indexPath, cell: cell)]
      }
    }()
    return makeSwipeActionConfiguration(actions: actions)
  }

  private func createHideSwipeAction(
    at indexPath: IndexPath, cell: TableCell,
    soundFontAndPatch: SoundFontAndPatch
  ) -> UIContextualAction {
    UIContextualAction(icon: .hide, color: .gray) { _, _, completionHandler in
      if Settings.shared.showedHidePresetPrompt {
        self.hidePreset(
          soundFontAndPatch: soundFontAndPatch, indexPath: indexPath,
          completionHandler: completionHandler)
      } else {
        self.promptToHidePreset(
          soundFontAndPatch: soundFontAndPatch, indexPath: indexPath,
          completionHandler: completionHandler)
      }
    }
  }

  private func makeSwipeActionConfiguration(actions: [UIContextualAction])
    -> UISwipeActionsConfiguration
  {
    let actions = UISwipeActionsConfiguration(actions: actions)
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }

  private func hidePreset(
    soundFontAndPatch: SoundFontAndPatch, indexPath: IndexPath,
    completionHandler: (Bool) -> Void
  ) {
    self.soundFonts.setVisibility(soundFontAndPatch: soundFontAndPatch, state: false)
    self.viewSlots.remove(at: indexPath.slotIndex)
    self.view.performBatchUpdates(
      {
        self.view.deleteRows(at: [indexPath], with: .automatic)
        self.sectionRowCounts[indexPath.section] -= 1
      },
      completion: { _ in
        self.updateSectionRowCounts(reload: true)
      })
    completionHandler(true)
  }

  private func promptToHidePreset(
    soundFontAndPatch: SoundFontAndPatch, indexPath: IndexPath,
    completionHandler: @escaping (Bool) -> Void
  ) {
    let promptTitle = Formatters.strings.hidePresetTitle
    let promptMessage = Formatters.strings.hidePresetMessage
    let alertController = UIAlertController(
      title: promptTitle, message: promptMessage, preferredStyle: .alert)

    let hide = UIAlertAction(title: Formatters.strings.hidePresetAction, style: .default) { _ in
      Settings.shared.showedHidePresetPrompt = true
      self.hidePreset(
        soundFontAndPatch: soundFontAndPatch, indexPath: indexPath,
        completionHandler: completionHandler)
    }

    let cancel = UIAlertAction(title: Formatters.strings.cancelAction, style: .cancel) { _ in
      completionHandler(false)
    }

    alertController.addAction(hide)
    alertController.addAction(cancel)

    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(
        x: self.view.bounds.midX, y: self.view.bounds.midY,
        width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    viewController?.present(alertController, animated: true, completion: nil)
  }
}

// MARK: - Updates

extension PatchesTableViewManager {

  private func getSlot(at indexPath: IndexPath) -> Slot {
    showingSearchResults ? searchSlots[indexPath] : viewSlots[indexPath]
  }

  private func makeSoundFontAndPatch(at indexPath: IndexPath) -> SoundFontAndPatch? {
    guard let soundFont = selectedSoundFontManager.selected else { return nil }
    let presetIndex: Int = {
      switch getSlot(at: indexPath) {
      case .favorite(let key): return favorites.getBy(key: key).soundFontAndPatch.patchIndex
      case .preset(let presetIndex): return presetIndex
      }
    }()
    return SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: presetIndex)
  }

  private func updateRow(with activeKind: ActivePatchKind?) {
    os_log(.debug, log: log, "updateView - with activeKind")
    guard let activeKind = activeKind else { return }
    switch activeKind {
    case .none: return
    case .preset(let soundFontAndPatch): updateRow(with: soundFontAndPatch)
    case .favorite(let favorite): updateRow(with: favorite)
    }
  }

  private func updateRow(with favorite: LegacyFavorite) {
    os_log(.debug, log: log, "updateRow - with favorite")
    guard let indexPath = getPresetIndexPath(for: favorite.key),
      let cell: TableCell = view.cellForRow(at: indexPath)
    else { return }
    updateCell(cell: cell, at: indexPath)
  }

  private func updateRow(with soundFontAndPatch: SoundFontAndPatch?) {
    os_log(.debug, log: log, "updateRow - with soundFontAndPatch")
    guard let indexPath = getPresetIndexPath(for: soundFontAndPatch),
      let cell: TableCell = view.cellForRow(at: indexPath)
    else { return }
    updateCell(cell: cell, at: indexPath)
  }

  private func getPresetIndexPath(for activeKind: ActivePatchKind) -> IndexPath? {
    switch activeKind {
    case .none: return nil
    case .preset(let soundFontAndPatch): return getPresetIndexPath(for: soundFontAndPatch)
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
      let soundFontAndPatch = SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: presetIndex)
      // FIXME: 2 crash reports where presetIndex is invalid
      let preset = soundFont.patches[max(presetIndex, soundFont.patches.count - 1)]
      os_log(.debug, log: log, "updateCell - preset '%{public}s' %d in row %d section %d",
             preset.presetConfig.name, presetIndex, indexPath.row, indexPath.section)
      cell.updateForPreset(name: preset.presetConfig.name,
                           isActive: soundFontAndPatch == activePatchManager.active.soundFontAndPatch
                                && activePatchManager.activeFavorite == nil)
    case let .favorite(key):
      let favorite = favorites.getBy(key: key)
      os_log(.debug, log: log, "updateCell - favorite '%{public}s' in row %d section %d",
             favorite.presetConfig.name, indexPath.row, indexPath.section)
      cell.updateForFavorite(name: favorite.presetConfig.name,
                             isActive: activePatchManager.activeFavorite == favorite)
    }
    return cell
  }
}
