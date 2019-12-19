// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the SoundFont UITableView. This view shows all of the names of the SoundFont files that are available
 in the app.
 */
final class FontsTableViewManager: NSObject {
    private lazy var log = Logging.logger("FontDS")

    private let view: UITableView
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let fontEditorActionGenerator: FontEditorActionGenerator
    private let soundFonts: SoundFonts
    private let deleteButton: UIButton

    init(view: UITableView, selectedSoundFontManager: SelectedSoundFontManager, activePatchManager: ActivePatchManager,
         fontEditorActionGenerator: FontEditorActionGenerator, soundFonts: SoundFonts, deleteButton: UIButton) {

        self.view = view
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.fontEditorActionGenerator = fontEditorActionGenerator
        self.soundFonts = soundFonts
        self.deleteButton = deleteButton

        super.init()

        view.register(FontCell.self)
        view.dataSource = self
        view.delegate = self

        soundFonts.subscribe(self, closure: soundFontsChange)
        selectedSoundFontManager.subscribe(self, closure: selectedSoundFontChange)
        activePatchManager.subscribe(self, closure: activePatchChange)
    }

    func selectActive() {
        if let index = soundFonts.index(of: activePatchManager.soundFont.key) {
            let indexPath = IndexPath(row: index, section: 0)
            view.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            view.scrollToRow(at: indexPath, at: .none, animated: true)
            deleteButton.isEnabled = activePatchManager.soundFont.removable
        }
        else {
            deleteButton.isEnabled = false
        }
    }
}

// MARK: - UITableViewDataSource Protocol

extension FontsTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { soundFonts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(for: indexPath), with: soundFonts.getBy(index: indexPath.row))
    }
}

// MARK: - UITableViewDelegate Protocol

extension FontsTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSoundFontManager.setSelected(soundFonts.getBy(index: indexPath.row))
        deleteButton.isEnabled = selectedSoundFontManager.selected.removable
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        deleteButton.isEnabled = false
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) ->
        UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) ->
        UISwipeActionsConfiguration? {
        guard let cell: FontCell = tableView.cellForRow(at: indexPath) else { return nil }
        let soundFont = soundFonts.getBy(index: indexPath.row)
        let action = fontEditorActionGenerator.createEditSwipeAction(at: cell, with: soundFont)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = true
        return actions
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) ->
        UISwipeActionsConfiguration? {
        guard let cell: FontCell = tableView.cellForRow(at: indexPath) else { return nil }
        let soundFont = soundFonts.getBy(index: indexPath.row)
        guard soundFont.removable else { return nil }
        let action = fontEditorActionGenerator.createDeleteSwipeAction(at: cell, with: soundFont, indexPath: indexPath)
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
        case let .active(old: old, new: new):

            selectedSoundFontManager.setSelected(new.soundFontPatch.soundFont)

            let oldRow = soundFonts.index(of: old.soundFontPatch.soundFont.key)
            let newRow = soundFonts.index(of: new.soundFontPatch.soundFont.key)
            if let row = oldRow, oldRow != newRow {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    os_log(.info, log: log, "updating old row %d", row)
                    update(cell: cell, with: old.soundFontPatch.soundFont)
                }
            }

            if let row = newRow {
                let indexPath = IndexPath(row: row, section: 0)
                if let cell: FontCell = view.cellForRow(at: indexPath) {
                    os_log(.info, log: log, "updating new row %d", row)
                    update(cell: cell, with: new.soundFontPatch.soundFont)
                }
            }
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        switch event {
        case let .changed(old: old, new: new):
            if let row = soundFonts.index(of: old.key) {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    os_log(.info, log: log, "updating old row %d", row)
                    update(cell: cell, with: old)
                }
            }

            if let row = soundFonts.index(of: new.key) {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    os_log(.info, log: log, "updating new row %d", row)
                    update(cell: cell, with: new)
                }
            }

            deleteButton.isEnabled = new.removable
        }
    }

    private func soundFontsChange(_ event: SoundFontsEvent) {
        os_log(.info, log: log, "soundFontsChange")
        switch event {
        case let .added(index, soundFont):
            let newPath = IndexPath(row: index, section: 0)
            view.performBatchUpdates({ self.addFont(newPath: newPath, soundFont: soundFont) },
                                     completion: { _ in
                                        self.completedAddFont(newPath: newPath, soundFont: soundFont) })

        case let .moved(old, new, soundFont):
            let oldPath = IndexPath(row: old, section: 0)
            let newPath = IndexPath(row: new, section: 0)
            view.performBatchUpdates({ self.moveFont(oldPath: oldPath, newPath: newPath, soundFont: soundFont) },
                                     completion: { _ in
                                        self.completedMoveFont(newPath: newPath, soundFont: soundFont) })

        case let .removed(old, deletedSoundFont):
            view.performBatchUpdates({ self.removeFont(index: old, soundFont: deletedSoundFont) },
                                     completion: { _ in
                                        self.completedRemoveFont(index: old, soundFont: deletedSoundFont) })
        }
    }

    private func addFont(newPath: IndexPath, soundFont: SoundFont) {
        view.insertRows(at: [newPath], with: .automatic)
        selectedSoundFontManager.setSelected(soundFont)
    }

    private func completedAddFont(newPath: IndexPath, soundFont: SoundFont) {
        view.selectRow(at: newPath, animated: true, scrollPosition: .none)
        view.scrollToRow(at: newPath, at: .none, animated: true)
    }

    private func moveFont(oldPath: IndexPath, newPath: IndexPath, soundFont: SoundFont) {
        view.moveRow(at: oldPath, to: newPath)
        if let cell: FontCell = view.cellForRow(at: oldPath) {
            update(cell: cell, with: soundFont)
        }
    }

    private func completedMoveFont(newPath: IndexPath, soundFont: SoundFont) {
        if selectedSoundFontManager.selected == soundFont {
            view.selectRow(at: newPath, animated: true, scrollPosition: .none)
            view.scrollToRow(at: newPath, at: .none, animated: true)
        }
    }

    private func removeFont(index: Int, soundFont: SoundFont) {
        let indexPath = IndexPath(row: index, section: 0)
        view.deleteRows(at: [indexPath], with: .automatic)
    }

    private func completedRemoveFont(index: Int, soundFont: SoundFont) {
        let newRow = min(index, soundFonts.count - 1)
        let newSoundFont = soundFonts.getBy(index: newRow)
        let newPath = IndexPath(row: newRow, section: 0)

        if self.activePatchManager.soundFont == soundFont {
            self.activePatchManager.setActive(.normal(soundFontPatch: SoundFontPatch(soundFont: newSoundFont,
                                                                                     patchIndex: 0)))
            self.selectedSoundFontManager.setSelected(newSoundFont)
        }
        else if self.selectedSoundFontManager.selected == soundFont {
            self.selectedSoundFontManager.setSelected(newSoundFont)
        }

        self.view.selectRow(at: newPath, animated: true, scrollPosition: .none)
        self.view.scrollToRow(at: newPath, at: .none, animated: true)
    }

    @discardableResult
    private func update(cell: FontCell, with soundFont: SoundFont) -> FontCell {
        let isSelected = selectedSoundFontManager.selected == soundFont
        cell.update(name: soundFont.displayName, isSelected: isSelected,
                    isActive: activePatchManager.active.soundFontPatch.soundFont == soundFont)
        if isSelected {
            if let indexPath = view.indexPath(for: cell) {
                view.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                view.scrollToRow(at: indexPath, at: .none, animated: false)
            }
        }

        cell.setNeedsDisplay()
        return cell
    }

    private func browserForNewFile() {

    }
}
