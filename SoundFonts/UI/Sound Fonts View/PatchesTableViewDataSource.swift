// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the Patches UITableView.
 */
final class PatchesTableViewDataSource: NSObject {

    /// Number of sections we partition patches into
    static private let sectionSize = 20

    private lazy var logger = Logging.logger("PTVDS")

    private let view: UITableView
    private let searchBar: UISearchBar
    private let activeSoundFontManager: ActiveSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let favoritesManager: FavoritesManager
    private let keyboardManager: KeyboardManager
    private var patches: [Patch] { activeSoundFontManager.selectedSoundFont.patches }

    // Hack to keep from redrawing a row when in a swipe action
    private var ignoreFavoriteRemove: Bool = false

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
        favoritesManager.addFavoriteChangeNotifier(self) { kind, favorite in
            if kind == .removed && self.ignoreFavoriteRemove == false {
                let patch = favorite.patch
                if activeSoundFontManager.selectedSoundFont == patch.soundFont {
                    self.view.reloadRows(at: [self.indexPathForPatchIndex(patch.index)], with: .none)
                }
            }
        }
    }

    /**
     Obtain an IndexPath for the given Patch index. A patch belongs in a section and a row within the section.
     
     - parameter index: the Patch index
     - returns: view IndexPath
     */
    func indexPathForPatchIndex(_ index: Int) -> IndexPath {
        let safeIndex = min(index, patches.count - 1)
        let section = safeIndex / Self.sectionSize
        let row = safeIndex - Self.sectionSize * section
        return IndexPath(row: row, section: section)
    }

    /**
     Obtain a Patch index for the given view IndexPath. This is the inverse of `indexPathForPatchIndex`.
     
     - parameter indexPath: the IndexPath to convert
     - returns: Patch index
     */
    func patchIndexForIndexPath(_ indexPath: IndexPath) -> Int {
        indexPath.section * PatchesTableViewDataSource.sectionSize + indexPath.row
    }
    
    /**
     Update the given table cell with Patch state
    
     - parameter cell: the cell to update
     - parameter patch: the Patch to use for the updating
     */
    func update(cell: PatchCell, with patch: Patch) {
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
                self.ignoreFavoriteRemove = true
                self.favoritesManager.remove(patch: patch)
                self.ignoreFavoriteRemove = false
            }
            else {
                self.favoritesManager.add(patch: patch, keyboardLowestNote: lowestNote)
            }
            self.update(cell: cell, with: patch)
            completionHandler(true)
        }
        
        action.image = UIImage(named: isFave ? "Unfave" : "Fave")
        action.backgroundColor = isFave ? UIColor.gray : UIColor.orange
        return action
    }

    private func update(cell: PatchCell, at indexPath: IndexPath) {
        let patchIndex = patchIndexForIndexPath(indexPath)
        let patch = patches[patchIndex]
        update(cell: cell, with: patch)
    }
}

// MARK: - UITableViewDataSource Protocol
extension PatchesTableViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        indexPathForPatchIndex(patches.count - 1).section + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        min(patches.count - section * PatchesTableViewDataSource.sectionSize, PatchesTableViewDataSource.sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PatchCell = tableView.dequeueReusableCell(for: indexPath)
        update(cell: cell, at: indexPath)
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        [UITableView.indexSearch, "•"] +
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
        section == 0 ? 0.0 : 18.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "\(section * PatchesTableViewDataSource.sectionSize)"
    }
}

// MARK: - UITableViewDelegate Protocol
extension PatchesTableViewDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let cell: PatchCell = tableView.cellForRow(at: indexPath) {
            let action = createSwipeAction(at: cell, with: patches[patchIndexForIndexPath(indexPath)])
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activePatchManager.changePatch(kind: .normal(patch: patches[patchIndexForIndexPath(indexPath)]))
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        header.textLabel?.textColor = UIColor.lightGray
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = UIColor(hex: "303030")
    }
}
