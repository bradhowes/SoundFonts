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
        if let row = soundFonts.index(of: activePatchManager.soundFont.key) {
            deleteButton.isEnabled = activePatchManager.soundFont.removable
            selectAndShow(row: row)
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
        update(cell: tableView.dequeueReusableCell(for: indexPath), indexPath: indexPath)
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
            update(row: soundFonts.index(of: old.soundFontPatch.soundFont.key))
            update(row: soundFonts.index(of: new.soundFontPatch.soundFont.key))
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        switch event {
        case let .changed(old: old, new: new):
            update(row: soundFonts.index(of: old.key))
            if let new = soundFonts.index(of: new.key) {
                update(row: new)
                self.selectAndShow(row: new)
            }
            deleteButton.isEnabled = new.removable
        }
    }

    private func soundFontsChange(_ event: SoundFontsEvent) {
        os_log(.info, log: log, "soundFontsChange")
        switch event {
        case let .added(new, soundFont):
            view.performBatchUpdates({ self.addFont(new: new, soundFont: soundFont) },
                                     completion: { _ in
                                        self.completedAddFont(new: new, soundFont: soundFont) })

        case let .moved(old, new, soundFont):
            view.performBatchUpdates({ self.moveFont(old: old, new: new) },
                                     completion: { _ in
                                        self.completedMoveFont(new: new, soundFont: soundFont) })

        case let .removed(old, deletedSoundFont):
            view.performBatchUpdates({ self.removeFont(old: old) },
                                     completion: { _ in
                                        self.completedRemoveFont(old: old, soundFont: deletedSoundFont) })
        }
    }

    private func addFont(new: Int, soundFont: SoundFont) {
        view.insertRows(at: [getIndexPath(of: new)], with: .automatic)
        selectedSoundFontManager.setSelected(soundFont)
    }

    private func completedAddFont(new: Int, soundFont: SoundFont) {
        selectAndShow(row: new)
    }

    private func moveFont(old: Int, new: Int) {
        view.moveRow(at: getIndexPath(of: old), to: getIndexPath(of: new))
        update(row: old)
        update(row: new)
    }

    private func completedMoveFont(new: Int, soundFont: SoundFont) {
        if selectedSoundFontManager.selected == soundFont {
            selectAndShow(row: new)
        }
    }

    private func removeFont(old: Int) {
        view.deleteRows(at: [getIndexPath(of: old)], with: .automatic)
    }

    private func completedRemoveFont(old: Int, soundFont: SoundFont) {
        let newRow = min(old, soundFonts.count - 1)
        let newSoundFont = soundFonts.getBy(index: newRow)

        if self.activePatchManager.soundFont == soundFont {
            self.activePatchManager.setActive(.normal(soundFontPatch: SoundFontPatch(soundFont: newSoundFont,
                                                                                     patchIndex: 0)))
            self.selectedSoundFontManager.setSelected(newSoundFont)
        }
        else if self.selectedSoundFontManager.selected == soundFont {
            self.selectedSoundFontManager.setSelected(newSoundFont)
        }

        selectAndShow(row: newRow)
    }

    private func getIndexPath(of row: Int) -> IndexPath { IndexPath(row: row, section: 0) }

    private func selectAndShow(row: Int) {
        let indexPath = getIndexPath(of: row)
        view.performBatchUpdates({self.view.selectRow(at: indexPath, animated: true, scrollPosition: .none)},
                                 completion: {_ in self.view.scrollToRow(at: indexPath, at: .none, animated: true)})
    }

    private func update(row: Int?) {
        guard let row = row else { return }
        os_log(.info, log: log, "update - row %d", row)
        let indexPath = getIndexPath(of: row)
        if let cell: FontCell = view.cellForRow(at: indexPath) {
            os_log(.info, log: log, "updating row %d", row)
            update(cell: cell, indexPath: indexPath)
        }
    }

    @discardableResult
    private func update(cell: FontCell, indexPath: IndexPath) -> FontCell {
        let soundFont = soundFonts.getBy(index: indexPath.row)
        let isSelected = selectedSoundFontManager.selected == soundFont
        cell.update(name: soundFont.displayName, isSelected: isSelected,
                    isActive: activePatchManager.active.soundFontPatch.soundFont == soundFont)
        return cell
    }
}
