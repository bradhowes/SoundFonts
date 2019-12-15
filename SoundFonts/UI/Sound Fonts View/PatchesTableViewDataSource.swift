// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the Patches UITableView.
 */
final class PatchesTableViewDataSource: NSObject {

    /// Number of sections we partition patches into
    static private let sectionSize = 20

    private lazy var log = Logging.logger("PatDS")

    private let view: UITableView
    private let searchBar: UISearchBar
    private let activePatchManager: ActivePatchManager
    private let favorites: Favorites
    private let keyboard: Keyboard

    private var showingSoundFont: SoundFont
    private var patches: [Patch] { showingSoundFont.patches }
    private var filtered = [Patch]()

    init(view: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager,
         selectedSoundFontManager: SelectedSoundFontManager, favorites: Favorites, keyboard: Keyboard) {
        self.view = view
        self.searchBar = searchBar
        self.activePatchManager = activePatchManager
        self.showingSoundFont = activePatchManager.soundFont
        self.favorites = favorites
        self.keyboard = keyboard
        super.init()

        view.register(PatchCell.self)
        view.dataSource = self
        view.delegate = self
        searchBar.delegate = self

        selectedSoundFontManager.subscribe(self, closure: selectedSoundFontChange)
        activePatchManager.subscribe(self, closure: activePatchChange)
    }

    private func reloadView() {
        if let searchTerm = searchBar.searchTerm {
            os_log(.info, log: log, "reloadView - searching for '%s'", searchTerm)
            search(for: searchTerm)
        }
        else {
            os_log(.info, log: log, "reloadView - reloadData")
            view.reloadData()
        }
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        os_log(.info, log: log, "activePatchChange")
        switch event {
        case let .active(old: old, new: new):

            if showingSoundFont != new.soundFontPatch.soundFont {
                os_log(.info, log: log, "new soundFont '%s'", new.soundFontPatch.soundFont.description)
                showingSoundFont = new.soundFontPatch.soundFont
                reloadView()
            }
            else {
                os_log(.info, log: log, "same font")
                if old.soundFontPatch.soundFont == showingSoundFont {
                    if let indexPath = indexPath(of: old.soundFontPatch.patch) {
                        if let cell: PatchCell = view.cellForRow(at: indexPath) {
                            os_log(.info, log: log, "updating old row %d", indexPath.row)
                            update(cell: cell, with: old.soundFontPatch.patch)
                        }
                    }
                }
            }

            hideSearchBar()

            if let indexPath = indexPath(of: new.soundFontPatch.patch) {
                if let cell: PatchCell = view.cellForRow(at: indexPath) {
                    os_log(.info, log: log, "updating new row %d", indexPath.row)
                    update(cell: cell, with: new.soundFontPatch.patch)
                }

                os_log(.info, log: log, "selecting row '%s'", new.soundFontPatch.description)
                view.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                os_log(.info, log: log, "scrolling to row")
                view.scrollToRow(at: indexPath, at: .none, animated: false)
            }
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        switch event {
        case let .changed(old: _, new: new):
            if showingSoundFont != new {
                os_log(.info, log: log, "new soundFont '%s'", new.description)
                showingSoundFont = new
                reloadView()
            }
        }
    }

    private func indexPath(of patch: Patch) -> IndexPath? {
        if showingSearchResults {
            guard let row: Int = filtered.firstIndex(where: { $0.soundFontIndex == patch.soundFontIndex }) else {
                return nil
            }
            return IndexPath(row: row, section: 0)
        }

        let section = patch.soundFontIndex / Self.sectionSize
        let row = patch.soundFontIndex - Self.sectionSize * section
        return IndexPath(row: row, section: section)
    }

    /**
     Obtain a Patch index for the given view IndexPath. This is the inverse of `indexPath(of:)`.
     
     - parameter indexPath: the IndexPath to convert
     - returns: Patch index
     */
    private func patchIndex(of indexPath: IndexPath) -> Int {
        indexPath.section * Self.sectionSize + indexPath.row
    }
    
    private func makeSoundFontPatch(for patch: Patch) -> SoundFontPatch {
        SoundFontPatch(soundFont: showingSoundFont, patchIndex: patch.soundFontIndex)
    }

    /**
     Update the given table cell with Patch state
    
     - parameter cell: the cell to update
     - parameter patch: the Patch to use for the updating
     */
    @discardableResult
    private func update(cell: PatchCell, with patch: Patch) -> PatchCell {
        cell.update(name: patch.name, isActive: isActive(patch: patch), isFavorite: isFavored(patch: patch))
        return cell
    }

    private func isActive(patch: Patch) -> Bool {
        showingSoundFont == activePatchManager.active.soundFontPatch.soundFont &&
            patch.soundFontIndex == activePatchManager.soundFontPatch.patchIndex
    }

    private func isFavored(patch: Patch) -> Bool {
        return favorites.isFavored(soundFontPatch: makeSoundFontPatch(for: patch))
    }

    private var showingSearchResults: Bool { searchBar.searchTerm != nil }

    private func dismissSearchResults() {
        os_log(.info, log: log, "dismissSearchResults")
        searchBar.text = nil
        filtered.removeAll()
        view.reloadData()
    }

    private func search(for searchTerm: String) {
        os_log(.info, log: log, "search - '%s'", searchTerm)
        filtered = patches.filter { $0.name.localizedCaseInsensitiveContains(searchTerm) }
        os_log(.info, log: log, "found %d matches", filtered.count)
        view.reloadData()
    }

    func hideSearchBar() {
        if !showingSearchResults && view.contentOffset.y < searchBar.frame.size.height {
            os_log(.info, log: log, "hiding search bar")
            let offset = CGPoint(x: 0, y: searchBar.frame.size.height)
            UIView.animate(withDuration: 0.4) { self.view.contentOffset = offset }
        }
    }

    private func createFaveAction(at cell: PatchCell, with patch: Patch) -> UIContextualAction {
        let soundFontPatch = makeSoundFontPatch(for: patch)
        let lowestNote = keyboard.lowestNote
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.favorites.add(soundFontPatch: soundFontPatch, keyboardLowestNote: lowestNote)
            self.update(cell: cell, with: patch)
            completionHandler(true)
        }

        action.image = UIImage(named: "Fave")
        action.backgroundColor = UIColor.orange

        return action
    }

    private func createUnfaveAction(at cell: PatchCell, with patch: Patch) -> UIContextualAction {
        let soundFontPatch = makeSoundFontPatch(for: patch)
        guard let favorite = favorites.getBy(soundFontPatch: soundFontPatch) else { fatalError() }
        let index = favorites.index(of: favorite)
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.favorites.remove(index: index, bySwiping: true)
            self.update(cell: cell, with: patch)
            completionHandler(true)
        }

        action.image = UIImage(named: "Unfave")
        action.backgroundColor = UIColor.red

        return action
    }

    private func createEditAction(at cell: PatchCell, with patch: Patch) -> UIContextualAction {
        let soundFontPatch = makeSoundFontPatch(for: patch)
        guard let favorite = favorites.getBy(soundFontPatch: soundFontPatch) else { fatalError() }
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.favorites.beginEdit(favorite: favorite, view: cell)
            completionHandler(true)
        }

        action.image = UIImage(named: "Edit")
        action.backgroundColor = UIColor.orange

        return action
    }

    private func createLeadingSwipeActions(at cell: PatchCell, with patch: Patch) -> UISwipeActionsConfiguration? {
        let action = isFavored(patch: patch) ? createEditAction(at: cell, with: patch) :
            createFaveAction(at: cell, with: patch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = true
        return actions
    }

    private func createTrailingSwipeActions(at cell: PatchCell, with patch: Patch) -> UISwipeActionsConfiguration? {
        let actions = UISwipeActionsConfiguration(actions: isFavored(patch: patch) ?
            [createUnfaveAction(at: cell, with: patch)] :
            [])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func getBy(indexPath: IndexPath) -> Patch {
        showingSearchResults ? filtered[indexPath.row] : patches[patchIndex(of: indexPath)]
    }

    private func update(cell: PatchCell, at indexPath: IndexPath) -> PatchCell {
        update(cell: cell, with: getBy(indexPath: indexPath))
    }
}

// MARK: - UITableViewDataSource Protocol

extension PatchesTableViewDataSource: UITableViewDataSource {

    private var sectionCount: Int { Int((Float(patches.count) / Float(Self.sectionSize)).rounded(.up)) }

    func numberOfSections(in tableView: UITableView) -> Int {
        showingSearchResults ? 1 : sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showingSearchResults ? filtered.count : min(patches.count - section * Self.sectionSize, Self.sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(for: indexPath), at: indexPath)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        showingSearchResults ? nil :
            [UITableView.indexSearch, "•"] +
            stride(from: PatchesTableViewDataSource.sectionSize, to: patches.count - 1,
                   by: PatchesTableViewDataSource.sectionSize).map { "\($0)" }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {

            // Going to show the search bar. We first tell UITableView to show the 0 section which shows the first
            // patch. We then have the UITableView reveal the search bar by updating the contentOffset in an animation.
            // This is done in an async block on the main thread so that it happens *after* the movement to the 0
            // section.
            //
            DispatchQueue.main.async { UIView.animate(withDuration: 0.24) { self.view.contentOffset = CGPoint.zero } }
            self.searchBar.becomeFirstResponder()
        }
        else if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
        return max(0, index - 1)
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
        guard let cell: PatchCell = tableView.cellForRow(at: indexPath) else { return nil }
        return createLeadingSwipeActions(at: cell, with: getBy(indexPath: indexPath))
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: PatchCell = tableView.cellForRow(at: indexPath) else { return nil }
        return createTrailingSwipeActions(at: cell, with: getBy(indexPath: indexPath))
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let patch = getBy(indexPath: indexPath)
        let soundFontPatch = makeSoundFontPatch(for: patch)
        if let favorite = favorites.getBy(soundFontPatch: soundFontPatch) {
            activePatchManager.setActive(.favorite(favorite: favorite))
        }
        else {
            activePatchManager.setActive(.normal(soundFontPatch: soundFontPatch))
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.lightGray
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = UIColor(hex: "303030")
    }
}

// MARK: - UISearchBarDelegate Protocol

extension PatchesTableViewDataSource : UISearchBarDelegate {

    /**
     Notification that the content of the search field changed. Update the search results based on the new contents. If
     the search field is empty, replace the search results with the patch listing.

     - parameter searchBar: the UISearchBar where the event took place
     - parameter textDidChange: the current contents of the text field
     */
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchTerm = searchBar.searchTerm {
            search(for: searchTerm)
        }
        else {
            dismissSearchResults()
        }
    }
}
