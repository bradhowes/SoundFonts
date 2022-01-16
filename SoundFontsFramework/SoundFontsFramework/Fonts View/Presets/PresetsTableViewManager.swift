// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Number of sections we partition presets into

/**
 Backing data source the presets UITableView. This is one of the most complicated managers and it should be
 broken up into smaller components. There are four areas of functionality:

 - table view drawing and selecting
 - row visibility editing
 - searching
 - row swiping
 */
final class PresetsTableViewManager: NSObject, Tasking {
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
  private var sectionRowCounts = [0]
  private var visibilityEditor: PresetsTableRowVisibilityEditor?

  private var searchBar: UISearchBar { viewController.searchBar }
  private var isSearching: Bool { viewController.isSearching }
  private var isEditing: Bool { viewController.isEditing }

  public var selectedSoundFont: SoundFont? {
    guard let key = selectedSoundFontManager.selected else { return nil }
    return soundFonts.getBy(key: key)
  }

  public var presetConfigs: [(IndexPath, PresetConfig)] {
    guard let soundFont = selectedSoundFont else { return [] }
    return viewSlots.enumerated().map { item in
      let indexPath = indexPath(from: .init(rawValue: item.0))
      switch item.1 {
      case let .favorite(key): return (indexPath, favorites.getBy(key: key).presetConfig)
      case .preset(let presetIndex): return (indexPath, soundFont.presets[presetIndex].presetConfig)
      }
    }
  }

  public var visibilityState: [(IndexPath, Bool)] { presetConfigs.map { ($0.0, $0.1.isVisible) } }

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

    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChanged_BT)
    activePresetManager.subscribe(self, notifier: activePresetChanged_BT)
    favorites.subscribe(self, notifier: favoritesChanged_BT)
    soundFonts.subscribe(self, notifier: soundFontsChanged_BT)
  }
}

// MARK: Support for PresetTableViewController

extension PresetsTableViewManager {

  var activeSlotIndexPath: IndexPath? {
    if let slotIndex = activeSlotIndex {
      return indexPath(from: slotIndex)
    } else {
      return nil
    }
  }

  var sectionCount: Int { isSearching ? 1 : sectionRowCounts.count }

  func numberOfRows(section: Int) -> Int { searchSlots?.count ?? sectionRowCounts[section] }

  func update(cell: TableCell, at indexPath: IndexPath) -> UITableViewCell {
    update(cell: cell, at: indexPath, slotIndex: slotIndex(from: indexPath))
    return cell
  }

  var sectionIndexTitles: [String] { IndexPath.sectionsTitles(sourceSize: viewSlots.count) }

  func selectSlot(at indexPath: IndexPath) {
    switch getSlot(at: indexPath.slotIndex(using: sectionRowCounts)) {
    case let .preset(presetIndex): selectPreset(presetIndex)
    case let .favorite(key): selectFavorite(key)
    }
  }

  func setSlotVisibility(at indexPath: IndexPath, state: Bool) {
    os_log(.debug, log: log, "setSlotVisibility BEGIN - indexPath: %d.%d newState: %d", indexPath.section, indexPath.row,
           state)
    guard let soundFont = selectedSoundFont else {
      os_log(.error, log: log, "setSlotVisibility END - soundFont is nil")
      return
    }
    switch viewSlots[slotIndex(from: indexPath)] {
    case .favorite(let key): favorites.setVisibility(key: key, state: state)
    case .preset(let index): soundFonts.setVisibility(soundFontAndPreset: soundFont[index], state: state)
    }
  }

  func search(for searchTerm: String) {
    os_log(.debug, log: log, "search BEGIN - '%{public}s'", searchTerm)
    guard let soundFont = selectedSoundFont else { fatalError("attempting to search with nil soundFont") }

    if searchTerm.isEmpty {
      searchSlots = viewSlots
    }
    else {
      let matches = viewSlots.filter { slot in
        let name: String = {
          switch slot {
          case let .favorite(key): return favorites.getBy(key: key).presetConfig.name
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

  func showActiveSlot() {
    os_log(.debug, log: log, "showActiveSlot - BEGIN")
    if let slotIndex = activeSlotIndex {
      os_log(.debug, log: log, "showActiveSlot - BEGIN")
      viewController.slotToScrollTo = indexPath(from: slotIndex)
    }
  }

  func beginVisibilityEditing() -> [IndexPath]? {
    guard let soundFont = selectedSoundFont else { return nil }
    var visibilityEditor = PresetsTableRowVisibilityEditor(viewSlots: viewSlots, sectionRowCounts: sectionRowCounts,
                                                           soundFont: soundFont, favorites: favorites)
    let insertions = visibilityEditor.begin()
    self.visibilityEditor = visibilityEditor
    if !insertions.isEmpty {
      self.viewSlots = visibilityEditor.viewSlots
      self.sectionRowCounts = visibilityEditor.sectionRowCounts
    }
    return insertions
  }

  func endVisibilityEditing() -> [IndexPath]? {
    guard var visibilityEditor = visibilityEditor else { return nil }

    let deletions = visibilityEditor.end()
    if !deletions.isEmpty {
      viewSlots = visibilityEditor.viewSlots
      sectionRowCounts = visibilityEditor.sectionRowCounts
    }

    self.visibilityEditor = nil
    return deletions
  }

  func regenerateViewSlots() {
    os_log(.info, log: log, "regenerateViewSlots BEGIN")
    guard soundFonts.restored && favorites.restored else {
      os_log(.info, log: log, "regenerateViewSlots END - not restored")
      return
    }

    let source = selectedSoundFont?.presets ?? []
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

    calculateSectionRowCounts()

    if isSearching {
      search(for: searchBar.nonNilSearchTerm)
      return
    }

    viewController.tableView.reloadData()
    os_log(.info, log: log, "regenerateViewSlots END")
  }
}

extension PresetsTableViewManager {

  private func activePresetChanged_BT(_ event: ActivePresetEvent) {
    switch event {
    case let .change(old: old, new: new, playSample: _):
      Self.onMain { self.handleActivePresetChanged(old: old, new: new) }
    }
  }

  private func selectedSoundFontChanged_BT(_ event: SelectedSoundFontEvent) {
    guard case let .changed(old, new) = event else { return }
    os_log(.debug, log: log, "selectedSoundFontChange - old: '%{public}s' new: '%{public}s'",
           old.descriptionOrNil, new.descriptionOrNil)
    Self.onMain { self.handleSelectedSoundFontChanged(old: old, new: new) }
  }

  private func favoritesChanged_BT(_ event: FavoritesEvent) {
    os_log(.debug, log: log, "favoritesChange BEGIN")
    switch event {
    case .restored:
      os_log(.info, log: log, "favoritesChange - restored")
      Self.onMain { self.favoritesRestored() }

    case let .added(_, favorite):
      os_log(.info, log: log, "favoritesChange - added - %{public}s", favorite.key.uuidString)

    case let .removed(_, favorite):
      os_log(.info, log: log, "favoritesChange - removed - %{public}s", favorite.key.uuidString)

    case let .changed(_, favorite):
      os_log(.info, log: log, "favoritesChange - changed - %{public}s", favorite.key.uuidString)
      Self.onMain { self.updateRow(with: favorite.key) }

    case .selected: break
    case .beginEdit: break
    case .removedAll: break
    }
    os_log(.debug, log: log, "favoritesChange END")
  }

  private func soundFontsChanged_BT(_ event: SoundFontsEvent) {
    os_log(.info, log: log, "soundFontsChange BEGIN")
    switch event {
    case let .unhidPresets(font: soundFont):
      if soundFont == self.selectedSoundFont {
        Self.onMain { self.regenerateViewSlots() }
      }

    case let .presetChanged(soundFont, index):
      if soundFont == selectedSoundFont {
        let soundFontAndPreset = soundFont[index]
        Self.onMain { self.updateRow(with: soundFontAndPreset) }
      }

    case .restored: Self.onMain { self.soundFontsRestored() }
    case .added: break
    case .moved: break
    case .removed: break
    }
    os_log(.info, log: log, "soundFontsChange END")
  }

  private func slotIndex(from indexPath: IndexPath) -> PresetViewSlotIndex {
    indexPath.slotIndex(using: sectionRowCounts)
  }

  private func indexPath(from slotIndex: PresetViewSlotIndex) -> IndexPath {
    .init(slotIndex: slotIndex, sectionRowCounts: sectionRowCounts)
  }

  private func selectPreset(_ presetIndex: Int) {
    guard let soundFont = selectedSoundFont else { return }
    let soundFontAndPreset = soundFont[presetIndex]
    activePresetManager.setActive(preset: soundFontAndPreset, playSample: settings.playSample)
  }

  private func selectFavorite(_ key: Favorite.Key) {
    let favorite = favorites.getBy(key: key)
    activePresetManager.setActive(favorite: favorite, playSample: settings.playSample)
  }

  private func calculateSectionRowCounts() {
    let numFullSections = viewSlots.count / IndexPath.sectionSize
    let remaining = viewSlots.count - numFullSections * IndexPath.sectionSize
    sectionRowCounts = [Int](repeating: IndexPath.sectionSize, count: numFullSections)
    if remaining > 0 || sectionRowCounts.isEmpty { sectionRowCounts.append(remaining) }
    precondition(!sectionRowCounts.isEmpty) // post-condition
  }

  private func handleActivePresetChanged(old: ActivePresetKind, new: ActivePresetKind) {
    os_log(.debug, log: log, "activePresetChange BEGIN")
    guard let slotIndex = getSlotIndex(for: new) else {
      os_log(.debug, log: log, "activePresetChange END - not showing font for new preset")
      return
    }
    viewController.slotToScrollTo = indexPath(from: slotIndex)
    viewController.tableView.performBatchUpdates(
      {
        updateRow(with: old)
        updateRow(with: new)
      },
      completion: { _ in })
    os_log(.debug, log: log, "activePresetChange END")
  }

  private func handleSelectedSoundFontChanged(old: SoundFont.Key?, new: SoundFont.Key?) {
    os_log(.debug, log: log, "handleSelectedSoundFontChanged BEGIN")

    let viewController = self.viewController
    if viewController.isEditing {
      os_log(.debug, log: log, "handleSelectedSoundFontChanged - stop editing")
      viewController.afterReloadDataAction = {
        viewController.endVisibilityEditing()
      }
    }
    else if activePresetManager.activeSoundFontKey == new {
      os_log(.debug, log: log, "handleSelectedSoundFontChanged - showing active slot")
      viewController.afterReloadDataAction = { self.showActiveSlot() }
    }

    regenerateViewSlots()
    os_log(.debug, log: log, "handleSelectedSoundFontChanged END")
  }

  private func favoritesRestored() {
    os_log(.info, log: log, "favoritesRestored BEGIN")
    regenerateViewSlots()
    os_log(.info, log: log, "favoritesRestored END")
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
          let soundFont = selectedSoundFont,
          soundFont.key == soundFontAndPreset.soundFontKey else {
            return nil
          }

    let presetIndex = soundFontAndPreset.presetIndex
    return isSearching ? searchSlots?.findPresetIndex(presetIndex) : viewSlots.findPresetIndex(presetIndex)
  }

  private var activeSlotIndex: PresetViewSlotIndex? {
    os_log(.debug, log: log, "activeSlotIndex BEGIN")
    guard let activeSlot: PresetViewSlot = {
      switch activePresetManager.active {
      case let .preset(soundFontAndPreset):
        os_log(.debug, log: log, "activeSlotIndex END - have preset")
        return .preset(index: soundFontAndPreset.presetIndex)
      case let .favorite(key, _):
        os_log(.debug, log: log, "activeSlotIndex END - have favorite")
        return .favorite(key: key)
      case .none:
        os_log(.debug, log: log, "activeSlotIndex END - has none")
        return nil
      }
    }()
    else {
      return nil
    }

    guard let slotIndex = (viewSlots.firstIndex { $0 == activeSlot }) else {
      os_log(.debug, log: log, "activeSlotIndex END - slot not found in viewSlots")
      return nil
    }

    os_log(.debug, log: log, "activeSlotIndex END - slotIndex: %d", slotIndex)
    return .init(rawValue: slotIndex)
  }

  private func isActive(_ soundFontAndPreset: SoundFontAndPreset) -> Bool {
    activePresetManager.active.soundFontAndPreset == soundFontAndPreset
  }
}

// MARK: - Swipe Actions

extension PresetsTableViewManager {

  func leadingSwipeActions(at indexPath: IndexPath, cell: TableCell) -> UISwipeActionsConfiguration? {
    guard let soundFont = selectedSoundFont else { return nil }
    let slotIndex = slotIndex(from: indexPath)
    let slot = getSlot(at: slotIndex)
    let actions: [UIContextualAction] = {
      switch slot {
      case let .preset(index):
        return [
          makeEditPresetSwipeAction(at: indexPath, soundFontAndPreset: soundFont[index]),
          makeCreateFavoriteSwipeAction(at: indexPath, soundFontAndPreset: soundFont[index])
        ]
      case .favorite:
        return [
          makeEditFavoriteSwipeAction(at: indexPath)
        ]
      }
    }()
    return makeSwipeActionConfiguration(actions: actions)
  }

  func trailingSwipeActions(at indexPath: IndexPath, cell: TableCell) -> UISwipeActionsConfiguration? {
    let slotIndex = slotIndex(from: indexPath)
    guard let soundFontAndPreset = makeSoundFontAndPreset(at: slotIndex) else { return nil }
    let slot = getSlot(at: slotIndex)
    let actions: [UIContextualAction] = {
      switch slot {
      case .preset:
        return [
          makeHideSwipeAction(at: indexPath, cell: cell, soundFontAndPreset: soundFontAndPreset)
        ]
      case .favorite:
        return [
          makeDeleteFavoriteSwipeAction(at: indexPath, cell: cell)
        ]
      }
    }()
    return makeSwipeActionConfiguration(actions: actions)
  }

  private func makeSwipeActionConfiguration(actions: [UIContextualAction]) -> UISwipeActionsConfiguration {
    let actions = UISwipeActionsConfiguration(actions: actions)
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }
}

// MARK: - Leading swipe actions

extension PresetsTableViewManager {

  private func makeEditPresetSwipeAction(at indexPath: IndexPath,
                                         soundFontAndPreset: SoundFontAndPreset) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemTeal) { [weak self] _, actionView, completionHandler in
      guard let self = self else { return }
      self.favorites.beginEdit(
        config: .preset(
          state: .init(
            indexPath: indexPath, sourceView: actionView, sourceRect: actionView.bounds,
            currentLowestNote: self.keyboard?.lowestNote,
            completionHandler: completionHandler, soundFonts: self.soundFonts,
            soundFontAndPreset: soundFontAndPreset,
            isActive: self.isActive(soundFontAndPreset),
            settings: self.settings))
      )
    }
  }

  private func makeCreateFavoriteSwipeAction(at indexPath: IndexPath,
                                             soundFontAndPreset: SoundFontAndPreset) -> UIContextualAction {
    UIContextualAction(icon: .favorite, color: .systemOrange) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      let status = self.createFavorite(at: indexPath, with: soundFontAndPreset)
      completionHandler(status)
    }
  }

  private func makeEditFavoriteSwipeAction(at indexPath: IndexPath) -> UIContextualAction {
    UIContextualAction(icon: .edit, color: .systemOrange) { [weak self] _, _, completionHandler in
      self?.editFavorite(at: indexPath, completionHandler: completionHandler)
    }
  }
}

// MARK: - Trailing swipe actions

extension PresetsTableViewManager {

  private func makeHideSwipeAction(at indexPath: IndexPath, cell: TableCell,
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

  private func makeDeleteFavoriteSwipeAction(at indexPath: IndexPath, cell: TableCell) -> UIContextualAction {
    UIContextualAction(icon: .unfavorite, color: .systemRed) { [weak self] _, _, completionHandler in
      guard let self = self else { return }
      completionHandler(self.deleteFavorite(at: indexPath, cell: cell))
    }
  }

  private func createFavorite(at indexPath: IndexPath, with soundFontAndPreset: SoundFontAndPreset) -> Bool {
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
      self.regenerateViewSlots()
    }

    return true
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
      self.regenerateViewSlots()
      if favorite == self.activePresetManager.activeFavorite {
        self.activePresetManager.setActive(preset: favorite.soundFontAndPreset, playSample: false)
      }
    }

    return true
  }

  private func editFavorite(at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
    let slotIndex = slotIndex(from: indexPath)
    guard case let .favorite(key) = getSlot(at: slotIndex) else { fatalError("unexpected nil") }
    let favorite = favorites.getBy(key: key)
    let position = favorites.index(of: favorite.key)
    var rect = viewController.tableView.rectForRow(at: indexPath)
    rect.size.width = 240.0
    let isActive = favorite.key == activePresetManager.activeFavorite?.key

    let configState = FavoriteEditor.State(
      indexPath: IndexPath(item: position, section: 0),
      sourceView: viewController.tableView, sourceRect: viewController.tableView.bounds,
      currentLowestNote: self.keyboard?.lowestNote,
      completionHandler: completionHandler,
      soundFonts: self.soundFonts,
      soundFontAndPreset: favorite.soundFontAndPreset,
      isActive: isActive,
      settings: settings)
    let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
    self.favorites.beginEdit(config: config)
  }

  private func hidePreset(soundFontAndPreset: SoundFontAndPreset, indexPath: IndexPath,
                          completionHandler: (Bool) -> Void) {
    let slotIndex = slotIndex(from: indexPath)
    self.soundFonts.setVisibility(soundFontAndPreset: soundFontAndPreset, state: false)
    viewController.tableView.performBatchUpdates {
      self.viewSlots.remove(at: slotIndex)
      viewController.tableView.deleteRows(at: [indexPath], with: .automatic)
      self.sectionRowCounts[indexPath.section] -= 1
    } completion: { _ in
      self.regenerateViewSlots()
    }
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
    guard let soundFont = selectedSoundFont else { return nil }
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
    case .favorite(let favoriteKey, _): updateRow(with: favoriteKey)
    }
  }

  private func updateRow(with favoriteKey: Favorite.Key) {
    os_log(.debug, log: log, "updateRow - with favorite")
    guard let slotIndex = getSlotIndex(for: favoriteKey),
          let cell: TableCell = viewController.tableView.cellForRow(at: indexPath(from: slotIndex))
    else { return }
    update(cell: cell, at: indexPath(from: slotIndex), slotIndex: slotIndex)
  }

  private func updateRow(with soundFontAndPreset: SoundFontAndPreset?) {
    os_log(.debug, log: log, "updateRow - with soundFontAndPreset")
    guard let slotIndex = getSlotIndex(for: soundFontAndPreset),
          let cell: TableCell = viewController.tableView.cellForRow(at: indexPath(from: slotIndex))
    else { return }
    update(cell: cell, at: indexPath(from: slotIndex), slotIndex: slotIndex)
  }

  private func getSlotIndex(for activeKind: ActivePresetKind) -> PresetViewSlotIndex? {
    switch activeKind {
    case .none: return nil
    case .preset(let soundFontAndPreset): return getSlotIndex(for: soundFontAndPreset)
    case .favorite(let favoriteKey, _): return getSlotIndex(for: favoriteKey)
    }
  }

  private func update(cell: TableCell, at indexPath: IndexPath, slotIndex: PresetViewSlotIndex) {
    guard let soundFont = selectedSoundFont else {
      os_log(.error, log: log, "unexpected nil soundFont")
      return
    }

    switch getSlot(at: slotIndex) {
    case let .preset(presetIndex):
      let soundFontAndPreset = soundFont[presetIndex]
      let preset = soundFont.presets[presetIndex]
      os_log(.debug, log: log, "updateCell - preset '%{public}s' %d in slot %d",
             preset.presetConfig.name, presetIndex, slotIndex.rawValue)
      var flags: TableCell.Flags = .init()
      if soundFontAndPreset == activePresetManager.active.soundFontAndPreset &&
          activePresetManager.activeFavorite == nil {
        flags.insert(.active)
      }
      if preset.presetConfig.presetTuning != 0.0 { flags.insert(.tuningSetting) }
      if preset.presetConfig.pan != 0.0 { flags.insert(.panSetting) }
      if preset.presetConfig.gain != 0.0 { flags.insert(.gainSetting) }
      cell.updateForPreset(at: indexPath, name: preset.presetConfig.name, flags: flags)

    case let .favorite(key):
      let favorite = favorites.getBy(key: key)
      os_log(.debug, log: log, "updateCell - favorite '%{public}s' in slot %d",
             favorite.presetConfig.name, slotIndex.rawValue)
      var flags: TableCell.Flags = [.favorite]
      if activePresetManager.activeFavorite == favorite { flags.insert(.active) }
      if favorite.presetConfig.presetTuning != 0.0 { flags.insert(.tuningSetting) }
      if favorite.presetConfig.pan != 0.0 { flags.insert(.panSetting) }
      if favorite.presetConfig.gain != 0.0 { flags.insert(.gainSetting) }
      cell.updateForFavorite(at: indexPath, name: favorite.presetConfig.name, flags: flags)
    }
  }
}
