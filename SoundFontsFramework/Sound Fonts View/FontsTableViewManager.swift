// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the SoundFont UITableView. This view shows all of the names of the SoundFont files that are available
 in the app.
 */
final class FontsTableViewManager: NSObject {
    private lazy var log = Logging.logger("FonTVM")

    private let view: UITableView
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let fontEditorActionGenerator: FontEditorActionGenerator
    private let soundFonts: SoundFonts

    init(view: UITableView, selectedSoundFontManager: SelectedSoundFontManager, activePatchManager: ActivePatchManager,
         fontEditorActionGenerator: FontEditorActionGenerator, soundFonts: SoundFonts) {

        self.view = view
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.fontEditorActionGenerator = fontEditorActionGenerator
        self.soundFonts = soundFonts

        super.init()

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self

        soundFonts.subscribe(self, notifier: soundFontsChange)
        selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
    }

    func selectActive() {
        guard let key = activePatchManager.soundFont?.key else { return }
        guard let row = soundFonts.index(of: key) else { return }
        selectAndShow(row: row)
    }

    public func reload() {
        view.reloadData()
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
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) ->
        UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
        let soundFont = soundFonts.getBy(index: indexPath.row)
        let action = fontEditorActionGenerator.createEditSwipeAction(at: indexPath, cell: cell, soundFont: soundFont)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = tableView.cellForRow(at: indexPath) else { return nil }
        let soundFont = soundFonts.getBy(index: indexPath.row)
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
                    let row = soundFonts.index(of: key)
                    update(row: row)
                }

                // Activating a patch automatically selects the soundfont associated with it
                if let soundFontAndPatch = new.soundFontAndPatch {
                    let key = soundFontAndPatch.soundFontKey
                    let row = soundFonts.index(of: key)
                    update(row: row)
                    selectedSoundFontManager.setSelected(activePatchManager.resolveToSoundFont(soundFontAndPatch))
                }
            }
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        if case let .changed(old: old, new: new) = event {
            if let key = old?.key, let row = soundFonts.index(of: key) {
                update(row: row)
            }

            if let key = new?.key, let row = soundFonts.index(of: key) {
                update(row: row)
                self.selectAndShow(row: row)
            }
        }
    }

    private func soundFontsChange(_ event: SoundFontsEvent) {
        os_log(.info, log: log, "soundFontsChange")
        switch event {
        case let .added(new, soundFont):
            view.performBatchUpdates({ view.insertRows(at: [getIndexPath(of: new)], with: .automatic) },
                                     completion: { _ in
                                        self.selectedSoundFontManager.setSelected(soundFont)
                                        self.selectAndShow(row: new)

            })

        case let .moved(old, new, soundFont):
            view.performBatchUpdates({ view.moveRow(at: getIndexPath(of: old), to: getIndexPath(of: new)) },
                                     completion: { _ in
                                        self.update(row: new)
                                        if self.selectedSoundFontManager.selected == soundFont {
                                            self.selectAndShow(row: new)
                                        }
            })

        case let .removed(old, deletedSoundFont):
            view.performBatchUpdates({ view.deleteRows(at: [getIndexPath(of: old)], with: .automatic) },
                                     completion: { _ in
                                        let newRow = min(old, self.soundFonts.count - 1)
                                        guard newRow >= 0 else {
                                            self.activePatchManager.setActive(.none, playSample: false)
                                            self.selectedSoundFontManager.setSelected(nil)
                                            return
                                        }

                                        let newSoundFont = self.soundFonts.getBy(index: newRow)
                                        if self.activePatchManager.soundFont == deletedSoundFont {
                                            self.activePatchManager.setActive(
                                                .normal(soundFontAndPatch:
                                                    SoundFontAndPatch(soundFontKey: newSoundFont.key, patchIndex: 0)), playSample: false)
                                            self.selectedSoundFontManager.setSelected(newSoundFont)
                                        }
                                        else if self.selectedSoundFontManager.selected == deletedSoundFont {
                                            self.selectedSoundFontManager.setSelected(newSoundFont)
                                        }

                                        self.selectAndShow(row: newRow)
            })

        case .restored: view.reloadData()
        }
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
        if let cell: TableCell = view.cellForRow(at: indexPath) {
            os_log(.info, log: log, "updating row %d", row)
            update(cell: cell, indexPath: indexPath)
        }
    }

    @discardableResult
    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        let soundFont = soundFonts.getBy(index: indexPath.row)
        let isSelected = selectedSoundFontManager.selected == soundFont
        let isActive = activePatchManager.soundFont == soundFont
        cell.updateForFont(name: soundFont.displayName, isSelected: isSelected, isActive: isActive)
        return cell
    }
}
