// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Data source for the SoundFont UITableView. This view shows all of the names of the SoundFont files that are available
 in the app.
 */
final class FontsTableViewDataSource: NSObject {

    private let view: UITableView
    private let searchBar: UISearchBar
    private let activeSoundFontManager: ActiveSoundFontManager
    private let soundFontEditor: SoundFontEditor
    private let collection: SoundFontLibraryManager

    private var data = [SoundFont]()
    private var indices = [UUID:Int]() {
        didSet {
            view.reloadData()
        }
    }

    init(view: UITableView, searchBar: UISearchBar, activeSoundFontManager: ActiveSoundFontManager,
         soundFontEditor: SoundFontEditor, collection: SoundFontLibraryManager) {

        self.view = view
        self.searchBar = searchBar
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

    func getBy(index: Int) -> SoundFont { data[index] }
    func index(of uuid: UUID) -> Int { indices[uuid]! }

    /**
     Create a swipe action for a cell / Patch which will add or remove a Favorite association with the Patch.

     - parameter cell: the cell that will show the action
     - parameter patch: the Patch to use when creating a new / removing an existing Favorite
     - returns: swipe action
     */
    private func createSwipeAction(at cell: FontCell, with soundFont: SoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "Edit") {
            (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            self.soundFontEditor.show(for: soundFont, cell: cell)
            completionHandler(true)
        }

        action.image = UIImage(named: "Edit")
        action.backgroundColor = UIColor.orange
        return action
    }

    private func collectionChanged(_ change: SoundFontLibraryChangeKind) {
        data = collection.orderedSoundFonts
        indices = Dictionary(uniqueKeysWithValues: data.enumerated().map { ($0.1.uuid, $0.0) })
    }

    /**
     Update a cell at a given row, and with the given FontCell instance.

     - parameter indexPath: location of row to update
     - parameter cell: FontCell to use for the update
     */
    private func updateCell(at indexPath: IndexPath, cell: FontCell) {
        cell.update(name: data[indexPath.row].displayName, isSelected: view.indexPathForSelectedRow == indexPath,
                    isActive: indexPath.row == activeSoundFontManager.activeIndex, isFavorite: false)
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
        activeSoundFontManager.selectedIndex = indexPath.row
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: FontCell = tableView.cellForRow(at: indexPath) {
            let soundFont = getBy(index: indexPath.row)
            let action = createSwipeAction(at: cell, with: soundFont)
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }

}
