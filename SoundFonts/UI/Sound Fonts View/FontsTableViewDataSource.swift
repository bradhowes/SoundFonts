// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the SoundFont UITableView. This view shows all of the names of the SoundFont files that are available
 in the app.
 */
final class FontsTableViewDataSource: NSObject {
    private lazy var logger = Logging.logger("FTVDS")

    private let view: UITableView
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let soundFontEditor: SoundFontEditor
    private let soundFonts: SoundFonts

    init(view: UITableView, selectedSoundFontManager: SelectedSoundFontManager, activePatchManager: ActivePatchManager,
         soundFontEditor: SoundFontEditor, soundFonts: SoundFonts) {

        self.view = view
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.soundFontEditor = soundFontEditor
        self.soundFonts = soundFonts

        super.init()

        view.register(FontCell.self)
        view.dataSource = self
        view.delegate = self

        soundFonts.subscribe(self, closure: soundFontsChanged)
        selectedSoundFontManager.subscribe(self, closure: selectedSoundFontChange)
        activePatchManager.subscribe(self, closure: activePatchChange)
    }
}

extension FontsTableViewDataSource {

    func activePatchChange(_ event: ActivePatchEvent) {
        switch event {
        case let .active(old: old, new: new):
            if let row = soundFonts.index(of: old.soundFontPatch.soundFont.uuid) {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    update(cell: cell, with: old.soundFontPatch.soundFont)
                }
            }

            if let row = soundFonts.index(of: new.soundFontPatch.soundFont.uuid) {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    update(cell: cell, with: new.soundFontPatch.soundFont)
                }
            }
        }
    }

    func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        switch event {
        case let .changed(old: old, new: new):
            if let row = soundFonts.index(of: old.uuid) {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    update(cell: cell, with: old)
                }
            }

            if let row = soundFonts.index(of: new.uuid) {
                if let cell: FontCell = view.cellForRow(at: IndexPath(row: row, section: 0)) {
                    update(cell: cell, with: new)
                }
            }
        }
    }

    private func soundFontsChanged(_ event: SoundFontsEvent) {
        switch event {
        case let .added(index, _):
            view.beginUpdates()
            view.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            view.endUpdates()
            break

        case let .moved(old, new, _):
            view.beginUpdates()
            view.moveRow(at: IndexPath(row: old, section: 0), to: IndexPath(row: new, section: 0))
            view.endUpdates()
            view.reloadRows(at: [IndexPath(row: old, section: 0), IndexPath(row: new, section: 0)], with: .automatic)
            break

        case let .removed(old, _):
            view.beginUpdates()
            view.deleteRows(at: [IndexPath(row: old, section: 0)], with: .automatic)
            view.endUpdates()
            break
        }
    }

    @discardableResult
    private func update(cell: FontCell, with soundFont: SoundFont) -> FontCell {
        cell.update(name: soundFont.displayName,
                    isSelected: selectedSoundFontManager.selected == soundFont,
                    isActive: activePatchManager.active.soundFontPatch.soundFont == soundFont)
        return cell
    }
}

// MARK: - UITableViewDataSource Protocol
extension FontsTableViewDataSource: UITableViewDataSource {
    
    /**
     Provide the number of sections in the table view
    
     - parameter tableView: the view to operate on
     - returns: always 1
     */
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    /**
     Provide the number of rows in the table view
    
     - parameter tableView: the view to operate on
     - parameter section: the section to operate on
     - returns: number of available SoundFont files
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { soundFonts.count }

    /**
     Provide a formatted FontCell for the table view
    
     - parameter tableView: the view to operate on
     - parameter indexPath: the position (row) of the cell to return
     - returns: FontCell instance to display
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return update(cell: tableView.dequeueReusableCell(for: indexPath), with: soundFonts.getBy(index: indexPath.row))
    }
}

// MARK: - UITableViewDelegate Protocol
extension FontsTableViewDataSource: UITableViewDelegate {

    /**
     Notification that the user selected a sound font.
    
     - parameter tableView: the view to operate on
     - parameter indexPath: the location that was selected
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSoundFontManager.setSelected(soundFonts.getBy(index: indexPath.row))
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: FontCell = tableView.cellForRow(at: indexPath) {
            let soundFont = soundFonts.getBy(index: indexPath.row)
            let action = soundFontEditor.createEditSwipeAction(at: cell, with: soundFont)
            let actions = UISwipeActionsConfiguration(actions: [action])
            actions.performsFirstActionWithFullSwipe = true
            return actions
        }
        return nil
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: FontCell = tableView.cellForRow(at: indexPath) {
            let soundFont = soundFonts.getBy(index: indexPath.row)
            if soundFont.removable  {
                let action = soundFontEditor.createDeleteSwipeAction(at: cell, with: soundFont, indexPath: indexPath)
                let actions = UISwipeActionsConfiguration(actions: [action])
                actions.performsFirstActionWithFullSwipe = false
                return actions
            }
        }
        return nil
    }
}
