// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Number of sections we partition presets into

/**
 Data source and delegate for the presets UITableView. This is one of the most complicated managers and it should be
 broken up into smaller components. There are four areas of functionality:

 - table view drawing and selecting
 - row visibility editing
 - searching
 - row swiping
 */
final class PresetsTableViewManager: NSObject {
  private lazy var log = Logging.logger("PresetsTableViewManager")

  private let viewController: PresetsTableViewController

  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePresetManager: ActivePresetManager
  private let soundFonts: SoundFonts
  private let favorites: Favorites
  private let keyboard: Keyboard?
  private let settings: Settings

  private var viewSlots = [PresetViewSlot]()
  private var searchSlots: [PresetViewSlot]?
  private var sectionRowCounts = [Int]()

  private var searchBar: UISearchBar { viewController.searchBar }
  private var isSearching: Bool { viewController.isSearching }
  private var isEditing: Bool { viewController.isEditing }

  public var selectedSoundFont: SoundFont? { selectedSoundFontManager.selected }

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
    self.settings = settings
    super.init()

    os_log(.info, log: log, "init")

    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
    activePresetManager.subscribe(self, notifier: activePresetChange)
    favorites.subscribe(self, notifier: favoritesChange)
    soundFonts.subscribe(self, notifier: soundFontsChange)
  }
}

// MARK: Support for PresetTableViewController

extension PresetsTableViewManager {

  var sectionCount: Int { isSearching ? 1 : sectionRowCounts.count }

  func numberOfRows(section: Int) -> Int { searchSlots?.count ?? sectionRowCounts[section] }

  func update(cell: TableCell, at indexPath: IndexPath) -> UITableViewCell {
    update(cell: cell, at: slotIndex(from: indexPath))
  }

  var sectionIndexTitles: [String] { IndexPath.sectionsTitles(sourceSize: viewSlots.count) }

  func selectSlot(at indexPath: IndexPath) {
    switch getSlot(at: indexPath.slotIndex(using: sectionRowCounts)) {
    case let .preset(presetIndex): selectPreset(presetIndex)
    case let .favorite(key): selectFavorite(key)
    }
  }

  func setSlotVisibility(at indexPath: IndexPath, state: Bool) {
    guard let soundFont = selectedSoundFont else { return }
    switch viewSlots[slotIndex(from: indexPath)] {
    case .favorite(let key): favorites.setVisibility(key: key, state: state)
    case .preset(let index): soundFonts.setVisibility(soundFontAndPreset: soundFont[index], state: state)
    }
  }

  func search(for searchTerm: String) {
    os_log(.debug, log: log, "search BEGIN - '%{public}s'", searchTerm)
    guard let soundFont = selectedSoundFontManager.selected else { fatalError("attempting to search with nil soundFont") }

    if searchTerm.isEmpty {
      searchSlots = viewSlots
    }
    else {
      let matches = viewSlots.filter { slot in
        let name: String = {
          switch slot {
          case .favorite(let key): return favorites.getBy(key: key).presetConfig.name
          case .preset(let presetIndex): return soundFont.presets[presetIndex].presetConfig.name
          }
        }()
        return name.localizedCaseInsensitiveContains(searchTerm)
      }
      searchSlots = matches
    }

    viewController.tableView.reloadData()

    os_log(.debug, log: log, "search END")
  }

  func cancelSearch() {
    searchSlots = nil
    regenerateViewSlots()
  }
}

extension PresetsTableViewManager {

  private func slotIndex(from indexPath: IndexPath) -> PresetViewSlotIndex {
    indexPath.slotIndex(using: sectionRowCounts)
  }

  private func indexPath(from slotIndex: PresetViewSlotIndex) -> IndexPath {
    .init(slotIndex: slotIndex, sectionRowCounts: sectionRowCounts)
  }

  private func selectPreset(_ presetIndex: Int) {
    guard let soundFont = selectedSoundFontManager.selected else { return }
    let soundFontAndPreset = soundFont[presetIndex]
    activePresetManager.setActive(preset: soundFontAndPreset, playSample: settings.playSample)
  }

  private func selectFavorite(_ key: Favorite.Key) {
    let favorite = favorites.getBy(key: key)
    activePresetManager.setActive(favorite: favorite, playSample: settings.playSample)
  }

  func calculateSectionRowCounts(reload: Bool) {
    let numFullSections = viewSlots.count / IndexPath.sectionSize
    let remaining = viewSlots.count - numFullSections * IndexPath.sectionSize
    sectionRowCounts = [Int](repeating: IndexPath.sectionSize, count: numFullSections)
    if remaining > 0 { sectionRowCounts.append(remaining) }
    if reload {
      viewController.tableView.reloadSections( IndexSet(stride(from: 0, to: sectionRowCounts.count, by: 1)), with: .none)
    }
  }

  func regenerateViewSlots() {
    os_log(.info, log: log, "regenerateViewSlots BEGIN")
    let source = selectedSoundFontManager.selected?.presets ?? []
    viewSlots.removeAll()
    for (index, preset) in source.enumerated() {
      if preset.presetConfig.isVisible {
        viewSlots.append(.preset(index: index))
      }
      for favoriteKey in preset.favorites {
        let favorite = favorites.getBy(key: favoriteKey)
        if favorite.presetConfig.isVisible {
          viewSlots.append(.favorite(key: favoriteKey))
        }
      }
    }

    calculateSectionRowCounts(reload: false)

    if isSearching {
      search(for: searchBar.nonNilSearchTerm)
      return
    }

    viewController.tableView.reloadData()
    os_log(.info, log: log, "regenerateViewSlots END")
  }

  func calculateVisibilityChanges(soundFont: SoundFont, isEditing: Bool) -> [IndexPath] {
    os_log(.debug, log: log, "calculateVisibilityChanges BEGIN")

    var changes = [IndexPath]()

    func processPresetConfig(_ slotIndex: PresetViewSlotIndex, presetConfig: PresetConfig, slot: () -> PresetViewSlot) {
      guard presetConfig.isVisible == false else { return }
      let indexPath = indexPath(from: slotIndex)
      if isEditing {
        os_log(.info, log: log, "slot %d showing - '%{public}s'", slotIndex.rawValue, presetConfig.name)
        viewSlots.insert(slot(), at: slotIndex.rawValue)
        changes.append(indexPath)
        sectionRowCounts[indexPath.section] += 1
      } else {
        os_log(.info, log: log, "slot %d hiding - '%{public}s'", slotIndex.rawValue, presetConfig.name)
        viewSlots.remove(at: slotIndex.rawValue - changes.count)
        changes.append(indexPath)
        sectionRowCounts[indexPath.section] -= 1
      }
    }

    var slotIndex: PresetViewSlotIndex = 0
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

    os_log(.debug, log: log, "calculateVisibilityChanges END - %d", changes.count)
    return changes
  }

  private func presetConfigForSlot(_ slot: PresetViewSlot) -> PresetConfig? {
    guard let soundFont = selectedSoundFontManager.selected else { return nil }
    switch slot {
    case .favorite(let key): return favorites.getBy(key: key).presetConfig
    case .preset(let presetIndex): return soundFont.presets[presetIndex].presetConfig
    }
  }

  func initializeVisibilitySelections(soundFont: SoundFont) {
    precondition(viewController.isEditing)
    os_log(.debug, log: self.log, "initializeVisibilitySelections")
    for (slotIndex, slot) in viewSlots.enumerated() {
      guard let presetConfig = presetConfigForSlot(slot) else { continue }
      if presetConfig.isVisible {
        viewController.tableView.selectRow(at: indexPath(from: .init(rawValue: slotIndex)), animated: false,
                                           scrollPosition: .none)
      }
    }
  }

  private func activePresetChange(_ event: ActivePresetEvent) {
    switch event {
    case let .active(old: old, new: new, playSample: _):
      os_log(.debug, log: log, "activePresetChange BEGIN")
      guard let slotIndex = getSlotIndex(for: new) else { return }
      viewController.slotToScrollTo = indexPath(from: slotIndex)
      viewController.tableView.performBatchUpdates(
        {
          updateRow(with: old)
          updateRow(with: new)
        },
        completion: { _ in })
    }
  }

  private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
    guard case let .changed(old: old, new: new) = event else { return }
    os_log(.debug, log: log, "selectedSoundFontChange - old: '%{public}s' new: '%{public}s'",
           old?.displayName ?? "N/A", new?.displayName ?? "N/A")

    let afterReloadDataAction: PresetsTableViewController.AfterReloadDataAction? = {
      if viewController.isEditing {
        guard let soundFont = new else { return nil }
        return { self.initializeVisibilitySelections(soundFont: soundFont) }
      }
      if activePresetManager.activeSoundFont == new {
        return { self.showActiveSlot() }
      }
      return nil
    }()

    viewController.afterReloadDataAction = afterReloadDataAction
    regenerateViewSlots()
    showActiveSlot()
  }

  private func favoritesChange(_ event: FavoritesEvent) {
    os_log(.debug, log: log, "favoritesChange BEGIN")
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
    os_log(.debug, log: log, "favoritesChange END")
  }

  private func favoritesRestored() {
    os_log(.info, log: log, "favoritesRestored BEGIN")
    regenerateViewSlots()
    os_log(.info, log: log, "favoritesRestored END")
  }

  private func soundFontsChange(_ event: SoundFontsEvent) {
    os_log(.info, log: log, "soundFontsChange BEGIN")
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
    os_log(.info, log: log, "soundFontsChange END")
  }

  private func soundFontsRestored() {
    os_log(.info, log: log, "soundFontsRestore BEGIN")
    regenerateViewSlots()
    os_log(.info, log: log, "soundFontsRestore END")
  }

  private func getSlotIndex(for key: Favorite.Key) -> PresetViewSlotIndex? {
    guard favorites.contains(key: key) else { return nil }
    return isSearching ? searchSlots?.findFavoriteKey(key) : viewSlots.findFavoriteKey(key)
  }

  private func getSlotIndex(for soundFontAndPreset: SoundFontAndPreset?) -> PresetViewSlotIndex? {
    guard let soundFontAndPreset = soundFontAndPreset,
          let soundFont = selectedSoundFontManager.selected,
          soundFont.key == soundFontAndPreset.soundFontKey else {
            return nil
          }

    let presetIndex = soundFontAndPreset.presetIndex
    return isSearching ? searchSlots?.findPresetIndex(presetIndex) : viewSlots.findPresetIndex(presetIndex)
  }

  public func showActiveSlot() {
    os_log(.info, log: log, "showActiveSlot BEGIN")

    guard let activeSlot: PresetViewSlot = {
      switch activePresetManager.active {
      case let .preset(soundFontAndPreset): return .preset(index: soundFontAndPreset.presetIndex)
      case let .favorite(favorite): return .favorite(key: favorite.key)
      case .none: return nil
      }
    }()
    else {
      os_log(.info, log: log, "showActiveSlot END - no active slot")
      return
    }

    guard let slotIndex = (viewSlots.firstIndex { $0 == activeSlot }) else {
      os_log(.info, log: log, "showActiveSlot END - active slot not found in viewSLots")
      return
    }

    viewController.slotToScrollTo = indexPath(from: .init(rawValue: slotIndex))

    os_log(.info, log: log, "showActiveSlot END")
  }

  private func isActive(_ soundFontAndPreset: SoundFontAndPreset) -> Bool {
    activePresetManager.active.soundFontAndPreset == soundFontAndPreset
  }
}

// MARK: - Swipe Actions

extension PresetsTableViewManager {

  func leadingSwipeActions(at indexPath: IndexPath, cell: TableCell) -> UISwipeActionsConfiguration? {
    let slotIndex = slotIndex(from: indexPath)
    let slot = getSlot(at: slotIndex)
    let actions: [UIContextualAction] = {
      switch slot {
      case .preset:
        guard let soundFontAndPreset = makeSoundFontAndPreset(at: slotIndex) else { return [] }
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
    UIContextualAction(icon: .edit, color: .systemTeal) { [weak self] _, actionView, completionHandler in
      guard let self = self else { return }
      var rect = self.viewController.tableView.rectForRow(at: indexPath)
      rect.size.width = 240.0
      self.favorites.beginEdit(
        config: FavoriteEditor.Config.preset(
          state: FavoriteEditor.State(
            indexPath: indexPath, sourceView: actionView, sourceRect: actionView.bounds,
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

    // The new index is below the source preset and all other favorites that are based on the preset
    let slotIndex = slotIndex(from: indexPath) + preset.favorites.count
    let favoriteIndex = IndexPath(slotIndex: slotIndex, sectionRowCounts: sectionRowCounts)

    viewController.tableView.performBatchUpdates {
      viewSlots.insert(.favorite(key: favorite.key), at: slotIndex)
      viewController.tableView.insertRows(at: [favoriteIndex], with: .automatic)
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
    let slotIndex = slotIndex(from: indexPath)
    guard case let .favorite(key) = getSlot(at: slotIndex) else { fatalError("unexpected slot type") }

    let favorite = favorites.getBy(key: key)
    favorites.remove(key: key)
    soundFonts.deleteFavorite(soundFontAndPreset: favorite.soundFontAndPreset, key: favorite.key)
    viewController.tableView.performBatchUpdates {
      viewSlots.remove(at: slotIndex)
      viewController.tableView.deleteRows(at: [indexPath], with: .automatic)
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
    let slotIndex = slotIndex(from: indexPath)
    guard case let .favorite(key) = getSlot(at: slotIndex) else { fatalError("unexpected nil") }
    let favorite = favorites.getBy(key: key)
    let position = favorites.index(of: favorite.key)
    var rect = viewController.tableView.rectForRow(at: indexPath)
    rect.size.width = 240.0
    let configState = FavoriteEditor.State(
      indexPath: IndexPath(item: position, section: 0),
      sourceView: viewController.tableView, sourceRect: viewController.tableView.bounds,
      currentLowestNote: self.keyboard?.lowestNote,
      completionHandler: completionHandler, soundFonts: self.soundFonts,
      soundFontAndPreset: favorite.soundFontAndPreset,
      settings: settings)
    let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
    self.favorites.beginEdit(config: config)
  }

  func trailingSwipeActions(at indexPath: IndexPath, cell: TableCell) -> UISwipeActionsConfiguration? {
    let slotIndex = slotIndex(from: indexPath)
    guard let soundFontAndPreset = makeSoundFontAndPreset(at: slotIndex) else { return nil }
    let slot = getSlot(at: slotIndex)
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
    let slotIndex = slotIndex(from: indexPath)
    self.soundFonts.setVisibility(soundFontAndPreset: soundFontAndPreset, state: false)
    self.viewSlots.remove(at: slotIndex)
    viewController.tableView.performBatchUpdates({
      viewController.tableView.deleteRows(at: [indexPath], with: .automatic)
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
      popoverController.sourceView = viewController.tableView
      let bounds = viewController.tableView.bounds
      popoverController.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    viewController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: - Updates

extension PresetsTableViewManager {

  private func getSlot(at slotIndex: PresetViewSlotIndex) -> PresetViewSlot {
    os_log(.debug, log: log, "getSlot BEGIN: %d %d %d", slotIndex.rawValue, searchSlots?.count ?? 0, viewSlots.count)
    return searchSlots?[slotIndex] ?? viewSlots[slotIndex]
  }

  private func makeSoundFontAndPreset(at slotIndex: PresetViewSlotIndex) -> SoundFontAndPreset? {
    guard let soundFont = selectedSoundFontManager.selected else { return nil }
    let presetIndex: Int = {
      switch getSlot(at: slotIndex) {
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
    guard let slotIndex = getSlotIndex(for: favorite.key),
          let cell: TableCell = viewController.tableView.cellForRow(at: indexPath(from: slotIndex))
    else { return }
    update(cell: cell, at: slotIndex)
  }

  private func updateRow(with soundFontAndPreset: SoundFontAndPreset?) {
    os_log(.debug, log: log, "updateRow - with soundFontAndPreset")
    guard let slotIndex = getSlotIndex(for: soundFontAndPreset),
          let cell: TableCell = viewController.tableView.cellForRow(at: indexPath(from: slotIndex))
    else { return }
    update(cell: cell, at: slotIndex)
  }

  private func getSlotIndex(for activeKind: ActivePresetKind) -> PresetViewSlotIndex? {
    switch activeKind {
    case .none: return nil
    case .preset(let soundFontAndPreset): return getSlotIndex(for: soundFontAndPreset)
    case .favorite(let favorite): return getSlotIndex(for: favorite.key)
    }
  }

  @discardableResult
  private func update(cell: TableCell, at slotIndex: PresetViewSlotIndex) -> TableCell {
    guard let soundFont = selectedSoundFontManager.selected else {
      os_log(.error, log: log, "unexpected nil soundFont")
      return cell
    }

    switch getSlot(at: slotIndex) {
    case let .preset(presetIndex):
      let soundFontAndPreset = soundFont[presetIndex]
      let preset = soundFont.presets[presetIndex]
      os_log(.debug, log: log, "updateCell - preset '%{public}s' %d in slot %d",
             preset.presetConfig.name, presetIndex, slotIndex.rawValue)
      cell.updateForPreset(name: preset.presetConfig.name,
                           isActive: soundFontAndPreset == activePresetManager.active.soundFontAndPreset
                           && activePresetManager.activeFavorite == nil)
    case let .favorite(key):
      let favorite = favorites.getBy(key: key)
      os_log(.debug, log: log, "updateCell - favorite '%{public}s' in slot %d",
             favorite.presetConfig.name, slotIndex.rawValue)
      cell.updateForFavorite(name: favorite.presetConfig.name,
                             isActive: activePresetManager.activeFavorite == favorite)
    }
    return cell
  }
}
