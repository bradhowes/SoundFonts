// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

private extension Int {
    var indexPath: IndexPath { IndexPath(row: self, section: 0) }
}

/**
 Data source and delegate for the SoundFont UITableView. This view shows all of the names of the SoundFont files that
 are available in the app.
 */
final class FontsTableViewManager: NSObject {
    private lazy var log = Logging.logger("FontsTVM")

    private let view: UITableView
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let fontEditorActionGenerator: FontEditorActionGenerator
    private let soundFonts: SoundFonts
    private let tags: Tags

    private var activeTagsObservation: NSKeyValueObservation?
    private var viewSoundFonts = [LegacySoundFont.Key]()
    private var filterTagKey: LegacyTag.Key = LegacyTag.allTag.key

    init(view: UITableView, selectedSoundFontManager: SelectedSoundFontManager, activePatchManager: ActivePatchManager,
         fontEditorActionGenerator: FontEditorActionGenerator, soundFonts: SoundFonts, tags: Tags) {

        self.view = view
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.fontEditorActionGenerator = fontEditorActionGenerator
        self.soundFonts = soundFonts
        self.tags = tags
        super.init()

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self

        soundFonts.subscribe(self, notifier: soundFontsChange)
        selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
        tags.subscribe(self, notifier: tagsChange)

        activeTagsObservation = Settings.shared.observe(\.activeTagIndex) { [weak self] setting, _ in
            self?.updateFilterTag(index: setting.activeTagIndex)
        }
    }

    private func updateFilterTag(index: Int) {
        let newTagKey = index == 0 ? LegacyTag.allTag.key : tags.getBy(index: index - 1).key
        if newTagKey != filterTagKey || viewSoundFonts.isEmpty {
            filterTagKey = newTagKey
            updateViewSoundFonts()
        }
    }

    private func updateViewSoundFonts() {
        guard tags.restored && soundFonts.restored else { return }
        viewSoundFonts = soundFonts.filtered(by: filterTagKey)
        os_log(.debug, log: log, "viewSoundFonts: %{public}@", viewSoundFonts.description)
        os_log(.debug, log: log, "names: %{public}@", soundFonts.names(of: viewSoundFonts).description)
        view.reloadData()
    }

    func selectActive() {
        guard let key = activePatchManager.soundFont?.key else { return }
        guard let row = viewSoundFonts.firstIndex(of: key) else { return }
        selectAndShow(row: row)
    }
}

// MARK: - UITableViewDataSource Protocol

extension FontsTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewSoundFonts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
    }
}

// MARK: - UITableViewDelegate Protocol

extension FontsTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let soundFont = soundFonts.getBy(key: viewSoundFonts[indexPath.row]) else { return }
        selectedSoundFontManager.setSelected(soundFont)
    }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
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

    private func activePatchChange(_ event: ActivePatchEvent) {
        os_log(.info, log: log, "activePatchChange")
        switch event {
        case let .active(old: old, new: new, playSample: _):
            if old.soundFontAndPatch?.soundFontKey != new.soundFontAndPatch?.soundFontKey {
                if let key = old.soundFontAndPatch?.soundFontKey {
                    let row = viewSoundFonts.firstIndex(of: key)
                    update(row: row)
                }

                if let soundFontAndPatch = new.soundFontAndPatch {
                    let key = soundFontAndPatch.soundFontKey
                    let row = viewSoundFonts.firstIndex(of: key)
                    update(row: row)
                    if let soundFont = activePatchManager.resolveToSoundFont(soundFontAndPatch) {
                        selectedSoundFontManager.setSelected(soundFont)
                    }
                    else {
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
                update(row: row)
            }

            if let key = new?.key, let row = viewSoundFonts.firstIndex(of: key) {
                update(row: row)
                self.selectAndShow(row: row)
            }
        }
    }

    private func addSoundFont(index: Int, soundFont: LegacySoundFont) {
        let filteredIndex = soundFonts.filteredIndex(index: index, tag: filterTagKey)
        guard filteredIndex >= 0 else {
            return
        }
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

    private func movedSoundFont(oldIndex: Int, newIndex: Int, soundFont: LegacySoundFont) {
        let oldFilteredIndex = soundFonts.filteredIndex(index: oldIndex, tag: filterTagKey)
        guard oldFilteredIndex >= 0 else { return }
        let newFilteredIndex = soundFonts.filteredIndex(index: newIndex, tag: filterTagKey)
        guard newFilteredIndex >= 0 else { return }
        view.performBatchUpdates {
            view.moveRow(at: oldFilteredIndex.indexPath, to: newFilteredIndex.indexPath)
            self.viewSoundFonts.insert(self.viewSoundFonts.remove(at: oldFilteredIndex), at: newFilteredIndex)
        } completion: { completed in
            if completed {
                self.update(row: newFilteredIndex)
                if self.selectedSoundFontManager.selected == soundFont {
                    self.selectAndShow(row: newFilteredIndex)
                }
            }
        }
    }

    private func removeSoundFont(index: Int, soundFont: LegacySoundFont) {
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

            guard let newSoundFont = self.soundFonts.getBy(key: self.viewSoundFonts[newRow]) else { return }
            if self.activePatchManager.soundFont == soundFont {
                self.activePatchManager.setActive(preset: SoundFontAndPatch(soundFontKey: newSoundFont.key,
                                                                            patchIndex: 0), playSample: false)
                self.selectedSoundFontManager.setSelected(newSoundFont)
            }
            else if self.selectedSoundFontManager.selected == soundFont {
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
            updateFilterTag(index: 0)

        case .restored: updateFilterTag(index: Settings.shared.activeTagIndex)
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

    private func update(row: Int?) {
        guard let row = row else { return }
        os_log(.info, log: log, "update - row %d", row)
        if let cell: TableCell = view.cellForRow(at: row.indexPath) {
            os_log(.info, log: log, "updating row %d", row)
            update(cell: cell, indexPath: row.indexPath)
        }
    }

    @discardableResult
    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        let key = viewSoundFonts[indexPath.row]
        guard let soundFont = soundFonts.getBy(key: key) else { fatalError("data out of sync") }
        let isSelected = selectedSoundFontManager.selected == soundFont
        let isActive = activePatchManager.soundFont == soundFont
        cell.updateForFont(name: soundFont.displayName, kind: soundFont.kind, isSelected: isSelected,
                           isActive: isActive)
        return cell
    }
}
