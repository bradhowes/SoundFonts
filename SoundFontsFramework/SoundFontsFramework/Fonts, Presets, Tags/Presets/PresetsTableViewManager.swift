// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Backing data source the presets UITableView. This is one of the most complicated managers and it should be
 broken up into smaller components. There are three areas of functionality:

 - row visibility editing
 - searching
 - row swiping
 */
final class PresetsTableViewManager: NSObject {
  private lazy var log = Logging.logger("PresetsTableViewManager")
  private let serialQueue = DispatchQueue(label: "PresetsTableViewManager", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .main)

  private let viewController: PresetsTableViewController

  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePresetManager: ActivePresetManager
  private let soundFonts: SoundFontsProvider
  private let favorites: FavoritesProvider
  private let keyboard: AnyKeyboard?
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
    return viewSlots.enumerated().compactMap { item in
      let indexPath = indexPath(from: .init(rawValue: item.0))
      switch item.1 {
      case let .favorite(key):
        guard let favorite = favorites.getBy(key: key) else { return nil }
        return (indexPath, favorite.presetConfig)
      case .preset(let presetIndex):
        return (indexPath, soundFont.presets[presetIndex].presetConfig)
      }
    }
  }

  public var visibilityState: [(IndexPath, Bool)] { presetConfigs.map { ($0.0, $0.1.isVisible) } }

  /**
   Construct a new presets table view manager.

   TODO: refactor to remove direct dependence on `viewController`.

   - parameter viewController: the view controller that holds this manager
   - parameter activePresetManager: the active preset manager
   - parameter selectedSoundFontManager: the selected sound font manager
   - parameter soundFonts: the sound fonts collection manager
   - parameter favorites: the favorites collection manager
   - parameter keyboard: the optional keyboard view manager
   - parameter infoBar: the info bar manager
   */
  init(viewController: PresetsTableViewController, activePresetManager: ActivePresetManager,
       selectedSoundFontManager: SelectedSoundFontManager, soundFonts: SoundFontsProvider, favorites: FavoritesProvider,
       keyboard: AnyKeyboard?, infoBar: AnyInfoBar, settings: Settings) {
    self.viewController = viewController
    self.selectedSoundFontManager = selectedSoundFontManager
    self.activePresetManager = activePresetManager
    self.soundFonts = soundFonts
    self.favorites = favorites
    self.keyboard = keyboard
    self.settings = settings
    super.init()

    os_log(.debug, log: log, "init")

    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChangedNotificationInBackground)
    activePresetManager.subscribe(self, notifier: activePresetChangedNotificationInBackground)
    favorites.subscribe(self, notifier: favoritesChangedNotificationInBackground)
    soundFonts.subscribe(self, notifier: soundFontsChangedNotificationInBackground)
  }
}

// MARK: Support for PresetTableViewController

// The functions in this section are those that are called on by PresetTableViewController. This should be factored out
// into a protocol for testing.
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
    } else {
      let matches = viewSlots.filter { slot in
        let name: String = {
          switch slot {
          case let .favorite(key):
            if let favorite = favorites.getBy(key: key) {
              return favorite.presetConfig.name
            } else {
              return ""
            }
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
    os_log(.debug, log: log, "regenerateViewSlots BEGIN")

    guard soundFonts.isRestored && favorites.isRestored else {
      os_log(.debug, log: log, "regenerateViewSlots END - not restored")
      return
    }

    let source = selectedSoundFont?.presets ?? []
    viewSlots.removeAll()

    for (index, preset) in source.enumerated() {
      if preset.presetConfig.isVisible {
        viewSlots.append(.preset(index: index))
      }
      for favoriteKey in preset.favorites {
        if let favorite = favorites.getBy(key: favoriteKey) {
          if favorite.presetConfig.isVisible {
            viewSlots.append(.favorite(key: favoriteKey))
          }
        }
      }
    }

    calculateSectionRowCounts()

    if isSearching {
      search(for: searchBar.nonNilSearchTerm)
      return
    }

    viewController.tableView.reloadData()
    os_log(.debug, log: log, "regenerateViewSlots END")
  }
}

extension PresetsTableViewManager {

  private func activePresetChangedNotificationInBackground(_ event: ActivePresetEvent) {
    switch event {
    case let .changed(old: old, new: new, playSample: _):
      serialQueue.async { self.handleActivePresetChanged(old: old, new: new) }
    }
  }

  private func selectedSoundFontChangedNotificationInBackground(_ event: SelectedSoundFontEvent) {
    guard case let .changed(old, new) = event else { return }
    os_log(.debug, log: log, "selectedSoundFontChangeNotificationInBackground - old: '%{public}s' new: '%{public}s'",
           old.descriptionOrNil, new.descriptionOrNil)
    serialQueue.async { self.handleSelectedSoundFontChanged(old: old, new: new) }
  }

  private func favoritesChangedNotificationInBackground(_ event: FavoritesEvent) {
    os_log(.debug, log: log, "favoritesChangeNotificationInBackground BEGIN")
    switch event {
    case .restored:
      os_log(.debug, log: log, "favoritesChangeNotificationInBackground - restored")
      serialQueue.async { self.handleFavoritesRestored() }

    case let .added(_, favorite):
      os_log(.debug, log: log, "favoritesChangeNotificationInBackground - added - %{public}s", favorite.key.uuidString)

    case let .removed(_, favorite):
      os_log(.debug, log: log, "favoritesChangeNotificationInBackground - removed - %{public}s", favorite.key.uuidString)

    case let .changed(_, favorite):
      os_log(.debug, log: log, "favoritesChangeNotificationInBackground - changed - %{public}s", favorite.key.uuidString)
      serialQueue.async { self.updateRow(with: favorite.key) }

    case .selected: break
    case .beginEdit: break
    case .removedAll: break
    }
    os_log(.debug, log: log, "favoritesChangeNotificationInBackground END")
  }

  private func soundFontsChangedNotificationInBackground(_ event: SoundFontsEvent) {
    os_log(.debug, log: log, "soundFontsChangedNotificationInBackground BEGIN")
    switch event {
    case let .unhidPresets(font: soundFont):
      if soundFont == self.selectedSoundFont {
        serialQueue.async { self.regenerateViewSlots() }
      }

    case let .presetChanged(soundFont, index):
      if soundFont == selectedSoundFont {
        let soundFontAndPreset = soundFont[index]
        serialQueue.async { self.updateRow(with: soundFontAndPreset) }
      }

    case .restored: serialQueue.async { self.handleSoundFontsRestored() }
    case .added: break
    case .moved: break
    case .removed: break
    }
    os_log(.debug, log: log, "soundFontsChangedNotificationInBackground END")
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
    if let favorite = favorites.getBy(key: key) {
      activePresetManager.setActive(favorite: favorite, playSample: settings.playSample)
    }
  }

  private func calculateSectionRowCounts() {
    let numFullSections = viewSlots.count / IndexPath.sectionSize
    let remaining = viewSlots.count - numFullSections * IndexPath.sectionSize
    sectionRowCounts = [Int](repeating: IndexPath.sectionSize, count: numFullSections)
    // There should always be at least one count, even if it is zero.
    if remaining > 0 || sectionRowCounts.isEmpty { sectionRowCounts.append(remaining) }
    precondition(!sectionRowCounts.isEmpty)
  }

  private func handleActivePresetChanged(old: ActivePresetKind, new: ActivePresetKind) {
    os_log(.debug, log: log, "handleActivePresetChanged BEGIN")

    if viewSlots.isEmpty {
      regenerateViewSlots()
      return
    }

    guard let slotIndex = getSlotIndex(for: new) else {
      os_log(.debug, log: log, "handleActivePresetChanged END - not showing font for new preset")
      return
    }

    viewController.slotToScrollTo = indexPath(from: slotIndex)
    viewController.tableView.performBatchUpdates({
      updateRow(with: old)
      updateRow(with: new)
    }, completion: { _ in })
    os_log(.debug, log: log, "handleActivePresetChanged END")
  }

  private func handleSelectedSoundFontChanged(old: SoundFont.Key?, new: SoundFont.Key?) {
    os_log(.debug, log: log, "handleSelectedSoundFontChanged BEGIN")

    if viewController.isEditing {
      os_log(.debug, log: log, "handleSelectedSoundFontChanged - stop editing")
      viewController.afterReloadDataAction = {
        self.viewController.endVisibilityEditing()
      }
    } else if activePresetManager.activeSoundFontKey == new {
      os_log(.debug, log: log, "handleSelectedSoundFontChanged - showing active slot")
      viewController.afterReloadDataAction = { self.showActiveSlot() }
    }

    regenerateViewSlots()

    os_log(.debug, log: log, "handleSelectedSoundFontChanged END")
  }

  private func handleFavoritesRestored() {
    os_log(.debug, log: log, "favoritesRestored BEGIN")
    regenerateViewSlots()
    os_log(.debug, log: log, "favoritesRestored END")
  }

  private func handleSoundFontsRestored() {
    os_log(.debug, log: log, "soundFontsRestore BEGIN")
    regenerateViewSlots()
    os_log(.debug, log: log, "soundFontsRestore END")
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

// These should be moved out into separate "actions" that are dedicated to performing one task.
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

  func beginEdit(at indexPath: IndexPath, view: UIView, completionHandler: @escaping (Bool) -> Void) {
    let slotIndex = slotIndex(from: indexPath)
    let slot = getSlot(at: slotIndex)
    guard let soundFontAndPreset = makeSoundFontAndPreset(at: slotIndex) else {
      DispatchQueue.main.async { completionHandler(false) }
      return
    }

    switch slot {
    case .preset:
      favorites.beginEdit(
        config: .preset(
          state: .init(
            indexPath: indexPath, sourceView: view, sourceRect: view.bounds,
            currentLowestNote: keyboard?.lowestNote, completionHandler: completionHandler, soundFonts: soundFonts,
            soundFontAndPreset: soundFontAndPreset, isActive: isActive(soundFontAndPreset), settings: settings)))
    case .favorite:
      editFavorite(at: indexPath, completionHandler: completionHandler)
    }
  }

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
    guard let favorite = favorites.getBy(key: key) else { return false }

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
    guard let favorite = favorites.getBy(key: key) else { return }
    guard let position = favorites.index(of: favorite.key) else { return }

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
    guard let presetIndex: Int = {
      switch getSlot(at: slotIndex) {
      case .favorite(let key):
        guard let favorite = favorites.getBy(key: key) else { return nil }
        return favorite.soundFontAndPreset.presetIndex
      case .preset(let presetIndex): return presetIndex
      }
    }() else { return nil }
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
    switch getSlot(at: slotIndex) {
    case let .preset(presetIndex):
      updatePresetCell(cell, indexPath: indexPath, presetIndex: presetIndex, slot: slotIndex.rawValue)
    case let .favorite(key):
      updateFavoriteCell(cell, indexPath: indexPath, key: key, slot: slotIndex.rawValue)
    }
  }

  func updatePresetCell(_ cell: TableCell, indexPath: IndexPath, presetIndex: Int, slot: Int) {
    guard let soundFont = selectedSoundFont else {
      os_log(.error, log: log, "unexpected nil soundFont")
      return
    }

    let soundFontAndPreset = soundFont[presetIndex]
    let preset = soundFont.presets[presetIndex]
    os_log(.debug, log: log, "updateCell - preset '%{public}s' %d in slot %d", preset.presetConfig.name, presetIndex,
           slot)
    var flags: TableCell.Flags = .init()
    if soundFontAndPreset == activePresetManager.active.soundFontAndPreset &&
        activePresetManager.activeFavorite == nil {
      flags.insert(.active)
    }
    if preset.presetConfig.presetTuning != 0.0 { flags.insert(.tuningSetting) }
    if preset.presetConfig.pan != 0.0 { flags.insert(.panSetting) }
    if preset.presetConfig.gain != 0.0 { flags.insert(.gainSetting) }
    cell.updateForPreset(at: indexPath, name: preset.presetConfig.name, flags: flags)
  }

  func updateFavoriteCell(_ cell: TableCell, indexPath: IndexPath, key: Favorite.Key, slot: Int) {
    guard let soundFont = selectedSoundFont else {
      os_log(.error, log: log, "unexpected nil soundFont")
      return
    }
    guard let favorite = favorites.getBy(key: key) else { return }
    os_log(.debug, log: log, "updateCell - favorite '%{public}s' in slot %d",
           favorite.presetConfig.name, slot)
    var flags: TableCell.Flags = [.favorite]
    if activePresetManager.activeFavorite == favorite { flags.insert(.active) }
    if favorite.presetConfig.presetTuning != 0.0 { flags.insert(.tuningSetting) }
    if favorite.presetConfig.pan != 0.0 { flags.insert(.panSetting) }
    if favorite.presetConfig.gain != 0.0 { flags.insert(.gainSetting) }
    cell.updateForFavorite(at: indexPath, name: favorite.presetConfig.name, flags: flags)
  }
}
