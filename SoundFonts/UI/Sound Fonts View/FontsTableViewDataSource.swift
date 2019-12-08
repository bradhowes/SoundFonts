// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Data source for the SoundFont UITableView. This view shows all of the names of the SoundFont files that are available
 in the app.
 */
final class FontsTableViewDataSource: NSObject {

    private let view: UITableView
    private let activeSoundFontManager: ActiveSoundFontManager
    private let soundFontEditor: SoundFontEditor
    private let collection: SoundFontLibraryManager

    private var data = [SoundFont]()
    private var indices = [UUID:Int]() {
        didSet {
            view.reloadData()
        }
    }

    init(view: UITableView, activeSoundFontManager: ActiveSoundFontManager, soundFontEditor: SoundFontEditor,
         collection: SoundFontLibraryManager) {

        self.view = view
        self.activeSoundFontManager = activeSoundFontManager
        self.soundFontEditor = soundFontEditor
        self.collection = collection

        super.init()
        
        view.register(FontCell.self)
        view.dataSource = self
        view.delegate = self

        collection.addSoundFontLibraryChangeNotifier(self, closure: collectionChanged)
    }
}

extension FontsTableViewDataSource {

    func index(of uuid: UUID) -> Int? { indices[uuid] }

    func getBy(index: Int) -> SoundFont { data[index] }

    func select(soundFont: SoundFont) {
        let pos = IndexPath(row: index(of: soundFont.uuid)!, section: 0)
        if view.indexPathForSelectedRow != pos {
            view.selectRow(at: pos, animated: true, scrollPosition: .none)
        }
        view.scrollToRow(at: pos, at: .none, animated: true)
    }

    private func collectionChanged(_ change: SoundFontLibraryChangeKind) {

        data = collection.orderedSoundFonts
        indices = Dictionary(uniqueKeysWithValues: data.enumerated().map { ($0.1.uuid, $0.0) })

        // TODO: fix this so that the selected index makes sense.
        // activeSoundFontManager.selectedIndex = 0
    }

    private func updateCell(at indexPath: IndexPath, cell: FontCell) {
        let index = indexPath.row
        let soundFont = data[index]
        cell.update(name: soundFont.displayName,
                    isSelected: activeSoundFontManager.selectedSoundFont == soundFont,
                    isActive: activeSoundFontManager.activeSoundFont == soundFont)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { data.count }

    /**
     Provide a formatted FontCell for the table view
    
     - parameter tableView: the view to operate on
     - parameter indexPath: the position (row) of the cell to return
     - returns: FontCell instance to display
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FontCell = tableView.dequeueReusableCell(for: indexPath)
        updateCell(at: indexPath, cell: cell)
        return cell
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
        activeSoundFontManager.selectedSoundFont = data[indexPath.row]
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: FontCell = tableView.cellForRow(at: indexPath) {
            let soundFont = data[indexPath.row]
            let action = self.soundFontEditor.createEditSwipeAction(at: cell, with: soundFont)
            let actions = UISwipeActionsConfiguration(actions: [action])
            actions.performsFirstActionWithFullSwipe = true
            return actions
        }
        return nil
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: FontCell = tableView.cellForRow(at: indexPath) {
            let soundFont = data[indexPath.row]
            if soundFont.removable  {
                let action = self.soundFontEditor.createDeleteSwipeAction(at: cell, with: soundFont)
                let actions = UISwipeActionsConfiguration(actions: [action])
                actions.performsFirstActionWithFullSwipe = false
                return actions
            }
        }
        return nil
    }
}
