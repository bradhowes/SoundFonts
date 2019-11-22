// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

/**
 Data source for the Patches UITableView.
 */
final class PatchesTableViewDataSource: NSObject {

    private let view: UITableView
    private let searchBar: UISearchBar
    private let activeSoundFontManager: ActiveSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let favoritesManager: FavoritesManager
    private let keyboardManager: KeyboardManager

    private var patches: [Patch] { return activePatchManager.patches }

    init(view: UITableView, searchBar: UISearchBar,
         activeSoundFontManager: ActiveSoundFontManager,
         activePatchManager: ActivePatchManager,
         favoritesManager: FavoritesManager,
         keyboardManager: KeyboardManager) {
        self.view = view
        self.searchBar = searchBar
        self.activeSoundFontManager = activeSoundFontManager
        self.activePatchManager = activePatchManager
        self.favoritesManager = favoritesManager
        self.keyboardManager = keyboardManager
        super.init()

        view.register(PatchCell.self)
        view.dataSource = self
        view.delegate = self

        // Receive notifications when a favorite is destroyed from within the favorite editor pane.
        favoritesManager.addFavoriteChangeNotifier(self) { obs, kind, favorite in
            if kind == .removed {
                let patch = favorite.patch
                guard let index = obs.patches.firstIndex(of: patch) else { return }
                obs.view.reloadRows(at: [self.indexPathForPatchIndex(index)], with: .none)
            }
        }
    }

    static private let sectionSize = 20
    
    /**
     Obtain an IndexPath for the given Patch index
     
     - parameter index: the Patch index
     - returns: view IndexPath
     */
    func indexPathForPatchIndex(_ index: Int) -> IndexPath {
        let section = index / PatchesTableViewDataSource.sectionSize
        return IndexPath(row: index - PatchesTableViewDataSource.sectionSize * section, section: section)
    }
    
    /**
     Obtain a Patch index for the given view IndexPath
     
     - parameter indexPath: the IndexPath to convert
     - returns: Patch index
     */
    func patchIndexForIndexPath(_ indexPath: IndexPath) -> Int {
        return indexPath.section * PatchesTableViewDataSource.sectionSize + indexPath.row
    }
    
    /**
     Update the given table cell with Patch state
    
     - parameter cell: the cell to update
     - parameter patch: the Patch to use for the updating
     */
    func updateCell(_ cell: PatchCell, with patch: Patch) {
        cell.update(name: patch.name,
                    index: patch.index,
                    isActive: activePatchManager.activePatch == patch,
                    isFavorite: favoritesManager.isFavored(patch: patch))
    }

    /**
     Create a swipe action for a cell / Patch which will add or remove a Favorite association with the Patch.
    
     - parameter cell: the cell that will show the action
     - parameter patch: the Patch to use when creating a new / removing an existing Favorite
     - returns: swipe action
     */
    func createSwipeAction(at cell: PatchCell, with patch: Patch) -> UIContextualAction {
        let isFave = favoritesManager.isFavored(patch: patch)
        let lowestNote = keyboardManager.lowestNote
        let action = UIContextualAction(style: .normal, title: isFave ? "Unfave" : "Fave") {
            (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            if isFave {
                self.favoritesManager.remove(patch: patch)
                self.updateCell(cell, with: patch)
            }
            else {
                self.favoritesManager.add(patch: patch, keyboardLowestNote: lowestNote)
                self.updateCell(cell, with: patch)
            }
            completionHandler(true)
        }
        
        action.image = UIImage(named: isFave ? "Unfave" : "Fave")
        action.backgroundColor = isFave ? UIColor.gray : UIColor.orange
        return action
    }

    private func updateCell(at indexPath: IndexPath, cell: PatchCell) {
        let patchIndex = patchIndexForIndexPath(indexPath)
        let patch = patches[patchIndex]
        updateCell(cell, with: patch)
    }
}

// MARK: - UITableViewDataSource Protocol
extension PatchesTableViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // + 1 for the search bar
        return indexPathForPatchIndex(patches.count - 1).section + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(patches.count - section * PatchesTableViewDataSource.sectionSize,
                   PatchesTableViewDataSource.sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PatchCell = tableView.dequeueReusableCell(for: indexPath)
        updateCell(at: indexPath, cell: cell)
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return [UITableView.indexSearch, "•"] +
            stride(from: PatchesTableViewDataSource.sectionSize, to: patches.count - 1,
                   by: PatchesTableViewDataSource.sectionSize).map { "\($0)" }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {
            tableView.scrollRectToVisible(searchBar.frame, animated: true)
            searchBar.becomeFirstResponder()
        }
        else if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
        return index - 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 18.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(section * PatchesTableViewDataSource.sectionSize)"
    }
}

// MARK: - UITableViewDataSource Protocol
extension PatchesTableViewDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: PatchCell = tableView.cellForRow(at: indexPath) {
            let action = createSwipeAction(at: cell, with: patches[patchIndexForIndexPath(indexPath)])
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activePatchManager.activePatch = patches[patchIndexForIndexPath(indexPath)]
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        header.textLabel?.textColor = UIColor.lightGray
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = UIColor(hex: "303030")
    }
}
