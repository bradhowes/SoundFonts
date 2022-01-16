// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

fileprivate extension Int {
  var indexPath: IndexPath { IndexPath(row: self, section: 0) }
}

/// Data source and delegate for the SoundFont UITableView. This view shows all of the names of the SoundFont files that
/// are available in the app.
final class FontsTableViewManager: NSObject, Tasking {
  private lazy var log = Logging.logger("FontsTableViewManager")

  private let view: UITableView
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePresetManager: ActivePresetManager
  private let activeTagManager: ActiveTagManager
  private let fontEditorActionGenerator: FontEditorActionGenerator
  private let soundFonts: SoundFonts
  private let tags: Tags
  private let settings: Settings

  private var dataSource = [SoundFont.Key]()
  private var filterTagKey: Tag.Key = Tag.allTag.key {
    didSet {
      settings.activeTagKey = filterTagKey
    }
  }

  init(view: UITableView, selectedSoundFontManager: SelectedSoundFontManager, activePresetManager: ActivePresetManager,
       activeTagManager: ActiveTagManager, fontEditorActionGenerator: FontEditorActionGenerator, soundFonts: SoundFonts,
       tags: Tags, settings: Settings) {

    self.view = view
    self.selectedSoundFontManager = selectedSoundFontManager
    self.activePresetManager = activePresetManager
    self.activeTagManager = activeTagManager
    self.fontEditorActionGenerator = fontEditorActionGenerator
    self.soundFonts = soundFonts
    self.tags = tags
    self.settings = settings
    super.init()

    view.register(TableCell.self)
    view.dataSource = self
    view.delegate = self

    soundFonts.subscribe(self, notifier: soundFontsChanged_BT)
    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChanged_BT)
    activePresetManager.subscribe(self, notifier: activePresetChanged_BT)
    activeTagManager.subscribe(self, notifier: activeTagChanged_BT)
    tags.subscribe(self, notifier: tagsChanged_BT)
  }

  func selectActive() {
    guard let key = activePresetManager.activeSoundFont?.key else { return }
    guard let row = dataSource.firstIndex(of: key) else { return }
    selectAndShow(row: row)
  }
}

// MARK: - UITableViewDataSource Protocol

extension FontsTableViewManager: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int { 1 }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataSource.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    updateCell(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }
}

// MARK: - UITableViewDelegate Protocol

extension FontsTableViewManager: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) else { return }
    selectedSoundFontManager.setSelected(soundFont)
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }

  func tableView(_ tableView: UITableView,
                 leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    guard let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) else { return nil }
    let action = fontEditorActionGenerator.createEditSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
    let actions = UISwipeActionsConfiguration(actions: [action])
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }

  func tableView(_ tableView: UITableView,
                 trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    guard let soundFont = soundFonts.getBy(key: dataSource[indexPath.row]) else { return nil }
    let action = fontEditorActionGenerator.createDeleteSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
    let actions = UISwipeActionsConfiguration(actions: [action])
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }
}

// MARK: - Private

extension FontsTableViewManager {

  private func soundFontsChanged_BT(_ event: SoundFontsEvent) {
    os_log(.info, log: log, "soundFontsChanged BEGIN - %{public}s", event.description)
    switch event {
    case let .added(new, soundFont):
      Self.onMain { self.addSoundFont(index: new, soundFont: soundFont) }
    case let .moved(old, new, soundFont):
      Self.onMain { self.movedSoundFont(oldIndex: old, newIndex: new, soundFont: soundFont) }
    case let .removed(old, deletedSoundFont):
      Self.onMain { self.removeSoundFont(index: old, soundFont: deletedSoundFont) }
    case .presetChanged: break
    case .unhidPresets: break
    case .restored:
      Self.onMain { self.updateTableView() }
    }
  }

  private func selectedSoundFontChanged_BT(_ event: SelectedSoundFontEvent) {
    os_log(.info, log: log, "selectedSoundFontChanged BEGIN - %{public}s", event.description)
    if case let .changed(old: old, new: new) = event {
      Self.onMain { self.handleFontChanged(old: old, new: new) }
    }
  }

  private func activePresetChanged_BT(_ event: ActivePresetEvent) {
    os_log(.info, log: log, "activePresetChanged BEGIN - %{public}s", event.description)
    switch event {
    case let .change(old: old, new: new, playSample: _):
      Self.onMain { self.handlePresetChanged(old: old, new: new) }
    }
  }

  private func activeTagChanged_BT(_ event: ActiveTagEvent) {
    os_log(.info, log: log, "activeTagChanged BEGIN - %{public}s", event.description)
    switch event {
    case let .change(old: old, new: new):
      Self.onMain { self.handleActiveTagChanged(old: old, new: new) }
    }
  }

  private func tagsChanged_BT(_ event: TagsEvent) {
    os_log(.info, log: log, "tagsChanged BEGIN - %{public}s", event.description)
    if case let .removed(_, tag) = event {
      Self.onMain { self.handleTagRemoved(tag) }
    }
  }

  private func handleTagRemoved(_ tag: Tag) {
    self.soundFonts.removeTag(tag.key)
    self.updateFilterTag(tagKey: Tag.allTag.key)
  }

  private func handleActiveTagChanged(old: Tag, new: Tag) {
    filterTagKey = new.key
    updateTableView()
  }

  private func updateFilterTag(tagKey: Tag.Key) {
    filterTagKey = tagKey
    updateTableView()
  }

  private func updateTableView() {
    os_log(.debug, log: log, "updateTableView BEGIN")
    guard tags.isRestored && soundFonts.isRestored else {
      os_log(.debug, log: log, "updateTableView END - not restored yet")
      return
    }

    dataSource = soundFonts.filtered(by: filterTagKey)
    os_log(.debug, log: log, "updateTableView - dataSource: %{public}s", dataSource.description)
    os_log(.debug, log: log, "updateTableView - names: %{public}s", soundFonts.names(of: dataSource).description)

    view.reloadData()
  }

  private func handlePresetChanged(old: ActivePresetKind, new: ActivePresetKind) {
    if old.soundFontAndPreset?.soundFontKey != new.soundFontAndPreset?.soundFontKey {
      if let key = old.soundFontAndPreset?.soundFontKey {
        let row = dataSource.firstIndex(of: key)
        updateRow(row: row)
      }

      if let soundFontAndPreset = new.soundFontAndPreset {
        let key = soundFontAndPreset.soundFontKey
        let row = dataSource.firstIndex(of: key)
        updateRow(row: row)
        if let soundFont = activePresetManager.resolveToSoundFont(soundFontAndPreset) {
          selectedSoundFontManager.setSelected(soundFont)
        } else {
          selectedSoundFontManager.clearSelected()
        }
      }
    }
  }

  private func handleFontChanged(old: SoundFont.Key?, new: SoundFont.Key?) {
    if let key = old, let row = dataSource.firstIndex(of: key) {
      updateRow(row: row)
    }

    if let key = new, let row = dataSource.firstIndex(of: key) {
      updateRow(row: row)
      selectAndShow(row: row)
    }
  }

  private func addSoundFont(index: Int, soundFont: SoundFont) {
    let filteredIndex = soundFonts.filteredIndex(index: index, tag: filterTagKey)
    guard filteredIndex >= 0 else { return }
    view.performBatchUpdates {
      view.insertRows(at: [filteredIndex.indexPath], with: .automatic)
      dataSource.insert(soundFont.key, at: filteredIndex)
    } completion: { completed in
      if completed {
        self.selectedSoundFontManager.setSelected(soundFont)
        self.selectAndShow(row: filteredIndex)
      }
    }
  }

  private func movedSoundFont(oldIndex: Int, newIndex: Int, soundFont: SoundFont) {
    let oldFilteredIndex = soundFonts.filteredIndex(index: oldIndex, tag: filterTagKey)
    guard oldFilteredIndex >= 0 else { return }
    let newFilteredIndex = soundFonts.filteredIndex(index: newIndex, tag: filterTagKey)
    guard newFilteredIndex >= 0 else { return }
    view.performBatchUpdates {
      view.moveRow(at: oldFilteredIndex.indexPath, to: newFilteredIndex.indexPath)
      self.dataSource.insert(self.dataSource.remove(at: oldFilteredIndex), at: newFilteredIndex)
    } completion: { completed in
      if completed {
        self.updateRow(row: newFilteredIndex)
        if self.selectedSoundFontManager.selected == soundFont.key {
          self.selectAndShow(row: newFilteredIndex)
        }
      }
    }
  }

  private func removeSoundFont(index: Int, soundFont: SoundFont) {
    let filteredIndex = soundFonts.filteredIndex(index: index, tag: filterTagKey)
    guard filteredIndex >= 0 else { return }
    view.performBatchUpdates {
      view.deleteRows(at: [filteredIndex.indexPath], with: .automatic)
      dataSource.remove(at: filteredIndex)
    } completion: { _ in
      let newRow = min(filteredIndex, self.dataSource.count - 1)
      guard newRow >= 0 else {
        self.selectedSoundFontManager.clearSelected()
        return
      }

      guard let newSoundFont = self.soundFonts.getBy(key: self.dataSource[newRow]) else {
        return
      }

      if self.activePresetManager.activeSoundFont == soundFont {
        self.activePresetManager.setActive(preset: .init(soundFontKey: newSoundFont.key,
                                                         soundFontName: newSoundFont.originalDisplayName,
                                                         presetIndex: 0,
                                                         itemName: newSoundFont.presets[0].presetConfig.name),
                                           playSample: false)
        self.selectedSoundFontManager.setSelected(newSoundFont)
      } else if self.selectedSoundFontManager.selected == soundFont.key {
        self.selectedSoundFontManager.setSelected(newSoundFont)
      }

      self.selectAndShow(row: newRow)
    }
  }

  private func selectAndShow(row: Int) {
    view.performBatchUpdates {
      self.view.selectRow(at: row.indexPath, animated: true, scrollPosition: .none)
    } completion: { _ in
      self.view.scrollToRow(at: row.indexPath, at: .none, animated: true)
    }
  }

  private func updateRow(row: Int?) {
    guard let row = row else { return }
    os_log(.debug, log: log, "updateRow - %d", row)
    if let cell: TableCell = view.cellForRow(at: row.indexPath) {
      updateCell(cell: cell, indexPath: row.indexPath)
    }
  }

  @discardableResult
  private func updateCell(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let key = dataSource[indexPath.row]
    guard let soundFont = soundFonts.getBy(key: key) else { fatalError("data out of sync") }
    os_log(.debug, log: log, "updateCell - font '%{public}s' %d", soundFont.displayName, indexPath.row)
    var flags: TableCell.Flags = .init()
    if selectedSoundFontManager.selected == soundFont.key { flags.insert(.selected) }
    if activePresetManager.activeSoundFontKey == soundFont.key { flags.insert(.active) }
    cell.updateForFont(at: indexPath, name: soundFont.displayName, kind: soundFont.kind, flags: flags)
    return cell
  }
}
