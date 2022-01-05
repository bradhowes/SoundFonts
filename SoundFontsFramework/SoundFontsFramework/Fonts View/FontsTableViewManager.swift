// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

extension Int {
  fileprivate var indexPath: IndexPath { IndexPath(row: self, section: 0) }
}

/// Data source and delegate for the SoundFont UITableView. This view shows all of the names of the SoundFont files that
/// are available in the app.
final class FontsTableViewManager: NSObject {
  private lazy var log = Logging.logger("FontsTableViewManager")

  private let view: UITableView
  private let selectedSoundFontManager: SelectedSoundFontManager
  private let activePresetManager: ActivePresetManager
  private let fontEditorActionGenerator: FontEditorActionGenerator
  private let soundFonts: SoundFonts
  private let tags: Tags
  private let settings: Settings

  private var activeTagsObservation: NSKeyValueObservation?
  private var viewSoundFonts = [SoundFont.Key]()
  private var filterTagKey: Tag.Key = Tag.allTag.key

  init(view: UITableView, selectedSoundFontManager: SelectedSoundFontManager, activePresetManager: ActivePresetManager,
       fontEditorActionGenerator: FontEditorActionGenerator, soundFonts: SoundFonts, tags: Tags, settings: Settings) {

    self.view = view
    self.selectedSoundFontManager = selectedSoundFontManager
    self.activePresetManager = activePresetManager
    self.fontEditorActionGenerator = fontEditorActionGenerator
    self.soundFonts = soundFonts
    self.tags = tags
    self.settings = settings
    super.init()

    view.register(TableCell.self)
    view.dataSource = self
    view.delegate = self

    soundFonts.subscribe(self, notifier: soundFontsChange)
    selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
    activePresetManager.subscribe(self, notifier: activePresetChange)
    tags.subscribe(self, notifier: tagsChange)

    _ = settings.activeTagKey
    activeTagsObservation = settings.observe(\.activeTagKey) { [weak self] setting, _ in
      self?.updateFilterTag(tagKey: setting.activeTagKey)
    }
  }

  func selectActive() {
    guard let key = activePresetManager.activeSoundFont?.key else { return }
    guard let row = viewSoundFonts.firstIndex(of: key) else { return }
    selectAndShow(row: row)
  }
}

// MARK: - UITableViewDataSource Protocol

extension FontsTableViewManager: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int { 1 }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewSoundFonts.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    updateCell(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }
}

// MARK: - UITableViewDelegate Protocol

extension FontsTableViewManager: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let soundFont = soundFonts.getBy(key: viewSoundFonts[indexPath.row]) else { return }
    selectedSoundFontManager.setSelected(soundFont)
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }

  func tableView(_ tableView: UITableView,
                 leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    guard let soundFont = soundFonts.getBy(key: viewSoundFonts[indexPath.row]) else { return nil }
    let action = fontEditorActionGenerator.createEditSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
    let actions = UISwipeActionsConfiguration(actions: [action])
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }

  func tableView(_ tableView: UITableView,
                 trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
    guard let soundFont = soundFonts.getBy(key: viewSoundFonts[indexPath.row]) else { return nil }
    let action = fontEditorActionGenerator.createDeleteSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
    let actions = UISwipeActionsConfiguration(actions: [action])
    actions.performsFirstActionWithFullSwipe = false
    return actions
  }
}

// MARK: - Private

extension FontsTableViewManager {

  private func updateFilterTag(tagKey: Tag.Key) {
    filterTagKey = tagKey
    DispatchQueue.main.async(execute: self.updateViewSoundFonts)
  }

  private func updateViewSoundFonts() {
    guard tags.restored && soundFonts.restored else { return }
    viewSoundFonts = soundFonts.filtered(by: filterTagKey)
    os_log(.debug, log: log, "viewSoundFonts: %{public}@", viewSoundFonts.description)
    os_log(.debug, log: log, "names: %{public}@", soundFonts.names(of: viewSoundFonts).description)
    view.reloadData()
  }

  private func activePresetChange(_ event: ActivePresetEvent) {
    os_log(.info, log: log, "activePresetChange")
    switch event {
    case let .active(old: old, new: new, playSample: _):
      if old.soundFontAndPreset?.soundFontKey != new.soundFontAndPreset?.soundFontKey {
        if let key = old.soundFontAndPreset?.soundFontKey {
          let row = viewSoundFonts.firstIndex(of: key)
          updateRow(row: row)
        }

        if let soundFontAndPreset = new.soundFontAndPreset {
          let key = soundFontAndPreset.soundFontKey
          let row = viewSoundFonts.firstIndex(of: key)
          updateRow(row: row)
          if let soundFont = activePresetManager.resolveToSoundFont(soundFontAndPreset) {
            selectedSoundFontManager.setSelected(soundFont)
          } else {
            selectedSoundFontManager.clearSelected()
          }
        }
      }
    }
  }

  private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
    os_log(.info, log: log, "selectedSoundFontChange")
    if case let .changed(old: old, new: new) = event {
      if let key = old?.key, let row = viewSoundFonts.firstIndex(of: key) {
        updateRow(row: row)
      }

      if let key = new?.key, let row = viewSoundFonts.firstIndex(of: key) {
        updateRow(row: row)
        self.selectAndShow(row: row)
      }
    }
  }

  private func addSoundFont(index: Int, soundFont: SoundFont) {
    let filteredIndex = soundFonts.filteredIndex(index: index, tag: filterTagKey)
    guard filteredIndex >= 0 else { return }
    view.performBatchUpdates {
      view.insertRows(at: [filteredIndex.indexPath], with: .automatic)
      viewSoundFonts.insert(soundFont.key, at: filteredIndex)
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
      self.viewSoundFonts.insert(self.viewSoundFonts.remove(at: oldFilteredIndex), at: newFilteredIndex)
    } completion: { completed in
      if completed {
        self.updateRow(row: newFilteredIndex)
        if self.selectedSoundFontManager.selected == soundFont {
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
      viewSoundFonts.remove(at: filteredIndex)
    } completion: { _ in
      let newRow = min(filteredIndex, self.viewSoundFonts.count - 1)
      guard newRow >= 0 else {
        self.selectedSoundFontManager.clearSelected()
        return
      }

      guard let newSoundFont = self.soundFonts.getBy(key: self.viewSoundFonts[newRow]) else {
        return
      }

      if self.activePresetManager.activeSoundFont == soundFont {
        self.activePresetManager.setActive(preset: .init(soundFontKey: newSoundFont.key,
                                                         soundFontName: newSoundFont.originalDisplayName,
                                                         presetIndex: 0,
                                                         itemName: newSoundFont.presets[0].presetConfig.name),
                                           playSample: false)
        self.selectedSoundFontManager.setSelected(newSoundFont)
      } else if self.selectedSoundFontManager.selected == soundFont {
        self.selectedSoundFontManager.setSelected(newSoundFont)
      }

      self.selectAndShow(row: newRow)
    }
  }

  private func soundFontsChange(_ event: SoundFontsEvent) {
    os_log(.info, log: log, "soundFontsChange")
    switch event {
    case let .added(new, soundFont): addSoundFont(index: new, soundFont: soundFont)
    case let .moved(old, new, soundFont): movedSoundFont(oldIndex: old, newIndex: new, soundFont: soundFont)
    case let .removed(old, deletedSoundFont): removeSoundFont(index: old, soundFont: deletedSoundFont)
    case .presetChanged: break
    case .unhidPresets: break
    case .restored: updateViewSoundFonts()
    }
  }

  private func tagsChange(_ event: TagsEvent) {
    switch event {
    case let .removed(_, tag):
      os_log(.info, log: log, "removing tag from fonts - %{public}@", tag.name)
      soundFonts.removeTag(tag.key)
      updateFilterTag(tagKey: Tag.allTag.key)

    case .restored: updateFilterTag(tagKey: settings.activeTagKey)
    case .added: break
    case .moved: break
    case .changed: break
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
    let key = viewSoundFonts[indexPath.row]
    guard let soundFont = soundFonts.getBy(key: key) else { fatalError("data out of sync") }
    os_log(.debug, log: log, "updateCell - font '%{public}s' %d", soundFont.displayName, indexPath.row)
    let isSelected = selectedSoundFontManager.selected == soundFont
    let isActive = activePresetManager.activeSoundFont == soundFont
    cell.updateForFont(name: soundFont.displayName, kind: soundFont.kind, isSelected: isSelected, isActive: isActive)
    return cell
  }
}
