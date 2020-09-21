// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the Patches UITableView.
 */
final class PatchesTableViewManager: NSObject {

    private lazy var log = Logging.logger("PatTVM")

    /// Number of sections we partition patches into
    private let sectionSize = 20

    private let view: UITableView
    private let searchBar: UISearchBar
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let favorites: Favorites
    private let keyboard: Keyboard?
    private let sampler: Sampler

    private var showingSoundFont: LegacySoundFont?
    private var patches: [LegacyPatch] { showingSoundFont?.patches ?? [] }
    private var filtered = [LegacyPatch]()

    private var sectionCount: Int { Int((Float(patches.count) / Float(sectionSize)).rounded(.up)) }

    init(view: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager,
         selectedSoundFontManager: SelectedSoundFontManager, favorites: Favorites, keyboard: Keyboard?,
         sampler: Sampler) {
        self.view = view
        self.searchBar = searchBar
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.showingSoundFont = activePatchManager.soundFont
        self.favorites = favorites
        self.keyboard = keyboard
        self.sampler = sampler
        super.init()

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
        searchBar.delegate = self

        selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
        favorites.subscribe(self, notifier: favoritesChange)

        view.sectionIndexColor = .darkGray

        let customFont = UIFont(name: "EurostileRegular", size: 20)!
        let defaultTextAttribs = [NSAttributedString.Key.font: customFont]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = defaultTextAttribs
    }
}

extension PatchesTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { showingSearchResults ? 1 : sectionCount }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showingSearchResults ? filtered.count : min(patches.count - section * sectionSize, sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(for: indexPath), at: indexPath, with: getSoundFontAndPatch(for: indexPath))
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !showingSearchResults else { return nil }
        return [UITableView.indexSearch, "•"] + stride(from: sectionSize, to: patches.count - 1, by: sectionSize).map { "\($0)" }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {

            // Going to show the search bar. We first tell UITableView to show the 0 section which shows the first
            // patch. We then have the UITableView reveal the search bar by updating the contentOffset in an animation.
            // This is done in an async block on the main thread so that it happens *after* the movement to the 0
            // section.
            //
            if !self.searchBar.isFirstResponder {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.24) { self.view.contentOffset = CGPoint.zero }
                }
                self.searchBar.becomeFirstResponder()
            }
            else {
                hideSearchBar(animated: true)
            }
        }
        else if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
        return max(0, index - 1)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { section == 0 ? 0.0 : 18.0 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "\(section * sectionSize)" }
}

// MARK: - UITableViewDelegate Protocol

extension PatchesTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        createLeadingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        createTrailingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if !showingSearchResults { dismissSearchKeyboard() }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let soundFontAndPatch = getSoundFontAndPatch(for: indexPath)
        dismissSearchResults()
        let playSample = settings.playSample
        if let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch) {
            activePatchManager.setActive(.favorite(favorite: favorite), playSample: playSample)
            let index = favorites.index(of: favorite)
            favorites.selected(index: index)
        }
        else {
            activePatchManager.setActive(.normal(soundFontAndPatch: soundFontAndPatch), playSample: playSample)
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .systemOrange
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        header.backgroundView = HeaderView()
        header.backgroundView?.backgroundColor = .black
    }
}

private class HeaderView: UIView {}

// MARK: - UISearchBarDelegate Protocol

extension PatchesTableViewManager: UISearchBarDelegate {

    func dismissSearchKeyboard() {
        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
    }

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
    }
}

// MARK: - Private

extension PatchesTableViewManager {

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
        case let .active(old: old, new: new, playSample: _):
            if showingSoundFont?.key != new.soundFontAndPatch?.soundFontKey {
                os_log(.info, log: log, "new font")
                if let soundFontAndPatch = new.soundFontAndPatch,
                    let soundFont = activePatchManager.resolveToSoundFont(soundFontAndPatch) {
                    selectedSoundFontManager.setSelected(soundFont)
                    view.performBatchUpdates({
                        self.view.reloadData()
                    }, completion: { finished in
                        if finished { self.selectActive(animated: true) }
                    })
                }
            }
            else {
                os_log(.info, log: log, "same font")
                if old.soundFontAndPatch?.soundFontKey == showingSoundFont?.key {
                    view.performBatchUpdates({
                        update(with: old.soundFontAndPatch)
                        update(with: new.soundFontAndPatch)
                    }, completion: { finished in
                        if finished { self.selectActive(animated: false) }
                    })
                }
            }
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        switch event {
        case let .changed(old: _, new: new):
            if showingSoundFont != new {
                showingSoundFont = new
                reloadView()
                DispatchQueue.main.async {
                    if self.activePatchManager.soundFont == new {
                        self.selectActive(animated: false)
                    }
                    else if !self.showingSearchResults {
                        self.hideSearchBar(animated: true)
                    }
                }
            }
        }
    }

    private func getFavorite(from event: FavoritesEvent) -> LegacyFavorite? {
        switch event {
        case let .added(index: _, favorite: favorite): return favorite
        case let .changed(index: _, favorite: favorite): return favorite
        case let .removed(index: _, favorite: favorite, bySwiping: _): return favorite
        default: return nil
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChange")
        if let favorite = getFavorite(from: event) {
            os_log(.info, log: log, "updating due to favorite")
            view.beginUpdates()
            update(with: favorite)
            view.endUpdates()
        }
    }

    private func getIndexPath(for soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
        guard let soundFontAndPatch = soundFontAndPatch else { return nil }
        guard showingSoundFont?.key == soundFontAndPatch.soundFontKey else { return nil }
        guard let patch = activePatchManager.resolveToPatch(soundFontAndPatch) else { return nil }
        if showingSearchResults {
            os_log(.info, "showing search results")
            guard let row: Int = filtered.firstIndex(where: { $0.soundFontIndex == patch.soundFontIndex }) else {
                os_log(.info, "not found in search results")
                return nil
            }
            os_log(.info, "IndexPath(row: %d  section: %d)", row, 0)
            return IndexPath(row: row, section: 0)
        }

        let section = patch.soundFontIndex / sectionSize
        let row = patch.soundFontIndex - sectionSize * section
        os_log(.info, "IndexPath(row: %d  section: %d)", row, section)
        return IndexPath(row: row, section: section)
    }

    /**
     Obtain a Patch index for the given view IndexPath. This is the inverse of `indexPath(of:)`.

     - parameter indexPath: the IndexPath to convert
     - returns: Patch index
     */
    private func patchIndex(of indexPath: IndexPath) -> Int { indexPath.section * sectionSize + indexPath.row }

    private func makeSoundFontAndPatch(for patch: LegacyPatch) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFontKey: showingSoundFont!.key, patchIndex: patch.soundFontIndex)
    }

    private func isActive(soundFontAndPatch: SoundFontAndPatch) -> Bool {
        activePatchManager.soundFontAndPatch == soundFontAndPatch
    }

    private var showingSearchResults: Bool { searchBar.searchTerm != nil }

    private func dismissSearchResults() {
        os_log(.info, log: log, "dismissSearchResults")
        searchBar.text = nil
        filtered.removeAll()
        view.reloadData()
        dismissSearchKeyboard()
    }

    private func search(for searchTerm: String) {
        os_log(.info, log: log, "search - '%s'", searchTerm)
        filtered = patches.filter { $0.name.localizedCaseInsensitiveContains(searchTerm) }
        os_log(.info, log: log, "found %d matches", filtered.count)
        view.reloadData()
    }

    func hideSearchBar(animated: Bool) {
        dismissSearchKeyboard()
        if showingSearchResults || view.contentOffset.y > searchBar.frame.size.height { return }
        os_log(.info, log: log, "hiding search bar")
        let view = self.view
        let contentOffset = CGPoint(x: 0, y: searchBar.frame.size.height)
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator( withDuration: 0.3, delay: 0.0, options: [.curveEaseOut], animations: { view.contentOffset = contentOffset },
                                                            completion: { _ in view.contentOffset = contentOffset })
        }
        else {
            view.contentOffset = contentOffset
        }
    }

    func selectActive(animated: Bool) {
        os_log(.info, log: log, "selectActive")
        if let indexPath = getIndexPath(for: activePatchManager.soundFontAndPatch) {
            self.view.layoutIfNeeded() // Needed so that we have a valid view state for the following to have any effect
            self.view.scrollToRow(at: indexPath, at: .none, animated: animated)
            self.view.selectRow(at: indexPath, animated: animated, scrollPosition: .none)
            self.hideSearchBar(animated: animated)
        }
    }

    private func createFaveSwipeAction(at: IndexPath, cell: TableCell,
                                       soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        let lowestNote = keyboard?.lowestNote
        guard let patch = activePatchManager.resolveToPatch(soundFontAndPatch) else { fatalError() }
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.favorites.add(name: patch.name, soundFontAndPatch: soundFontAndPatch, keyboardLowestNote: lowestNote)
            self.update(cell: cell, at: at, with: soundFontAndPatch)
            completionHandler(true)
        }
        action.image = UIImage.resourceImage(name: "Fave")
        action.backgroundColor = UIColor.orange
        action.accessibilityLabel = "FavoriteCreateButton"
        action.accessibilityHint = "FavoriteCreateButton"
        action.isAccessibilityElement = true
        return action
    }

    private func createUnfaveSwipeAction(at: IndexPath, cell: TableCell,
                                         soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        guard let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch) else { fatalError() }
        let index = favorites.index(of: favorite)
        let action = UIContextualAction(style: .normal, title: nil) { _, view, completionHandler in
            if favorite == self.activePatchManager.favorite {
                self.activePatchManager.setActive(.normal(soundFontAndPatch: favorite.soundFontAndPatch))
            }
            self.favorites.remove(index: index, bySwiping: true)
            self.view.beginUpdates()
            self.update(cell: cell, at: at, with: soundFontAndPatch)
            self.view.endUpdates()
            completionHandler(true)
        }
        action.image = UIImage.resourceImage(name: "Unfave")
        action.backgroundColor = UIColor.red
        return action
    }

    private func createEditSwipeAction(at: IndexPath, cell: TableCell,
                                       soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        guard let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch) else { fatalError() }
        guard let soundFont = activePatchManager.resolveToSoundFont(soundFontAndPatch) else { fatalError() }
        guard let patch = activePatchManager.resolveToPatch(soundFontAndPatch) else { fatalError() }
        let action = UIContextualAction(style: .normal, title: nil) { _, view, completionHandler in
            var rect = self.view.rectForRow(at: at)
            rect.size.width = 240.0
            let position = self.favorites.index(of: favorite)
            let config = FavoriteEditor.Config(indexPath: IndexPath(item: position, section: 0), view: view, rect: view.bounds, favorite: favorite,
                                               currentLowestNote: self.keyboard?.lowestNote, completionHandler: completionHandler, soundFont: soundFont, patch: patch)
            self.favorites.beginEdit(config: config)
        }

        action.image = UIImage.resourceImage(name: "Edit")
        action.backgroundColor = UIColor.orange
        action.accessibilityLabel = "FavoriteEditButton"
        action.accessibilityHint = "FavoriteEditButton"
        action.isAccessibilityElement = true
        return action
    }

    private func createLeadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let soundFontAndPatch = getSoundFontAndPatch(for: indexPath)
        let action = favorites.isFavored(soundFontAndPatch: soundFontAndPatch) ?
            createEditSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch) :
            createFaveSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func createTrailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let soundFontAndPatch = getSoundFontAndPatch(for: indexPath)
        let actions = UISwipeActionsConfiguration(actions: favorites.isFavored(soundFontAndPatch: soundFontAndPatch) ?
            [createUnfaveSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch)] : [])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func getSoundFontAndPatch(for indexPath: IndexPath) -> SoundFontAndPatch {
        makeSoundFontAndPatch(for: showingSearchResults ? filtered[indexPath.row] : patches[patchIndex(of: indexPath)])
    }

    @discardableResult
    private func update(with soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
        guard let indexPath = getIndexPath(for: soundFontAndPatch), let soundFontAndPatch = soundFontAndPatch else { return nil }
        update(at: indexPath, with: soundFontAndPatch)
        return indexPath
    }

    @discardableResult
    private func update(with favorite: LegacyFavorite) -> IndexPath? {
        guard let indexPath = getIndexPath(for: favorite.soundFontAndPatch) else { return nil }
        update(at: indexPath, with: favorite)
        return indexPath
    }

    private func update(at indexPath: IndexPath, with soundFontAndPatch: SoundFontAndPatch) {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        update(cell: cell, at: indexPath, with: soundFontAndPatch)
    }

    private func update(at indexPath: IndexPath, with favorite: LegacyFavorite) {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        update(cell: cell, at: indexPath, with: favorite)
    }

    /**
     Update the given table cell with Patch state. NOTE: *all* PatchCell updates should be done via this routine
     instead of direct `cell.update` calls.

     - parameter cell: the cell to update
     - parameter soundFontAndPatch: the soundfont and patch to use for the updating
     */
    @discardableResult
    private func update(cell: TableCell, at indexPath: IndexPath, with soundFontAndPatch: SoundFontAndPatch) -> TableCell {
        if let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch) {
            return update(cell: cell, at: indexPath, with: favorite)
        }
        guard let patch = activePatchManager.resolveToPatch(soundFontAndPatch) else { return cell }
        cell.updateForPatch(name: patch.name, isActive: isActive(soundFontAndPatch: soundFontAndPatch), isFavorite: false)
        return cell
    }

    @discardableResult
    private func update(cell: TableCell, at indexPath: IndexPath, with favorite: LegacyFavorite) -> TableCell {
        let active = isActive(soundFontAndPatch: favorite.soundFontAndPatch)
        cell.updateForPatch(name: favorite.name, isActive: active, isFavorite: true)
        return cell
    }
}
