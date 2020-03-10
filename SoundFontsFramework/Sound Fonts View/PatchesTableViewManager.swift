// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source for the Patches UITableView.
 */
final class PatchesTableViewManager: NSObject {

    /// Number of sections we partition patches into
    static private let sectionSize = 20

    private lazy var log = Logging.logger("PatTVM")

    private let view: UITableView
    private let searchBar: UISearchBar
    private let activePatchManager: ActivePatchManager
    private let favorites: Favorites
    private let keyboard: Keyboard?
    private let sampler: Sampler

    private var showingSoundFont: SoundFont?
    private var patches: [Patch] { showingSoundFont?.patches ?? [] }
    private var filtered = [Patch]()

    private var sectionCount: Int { Int((Float(patches.count) / Float(Self.sectionSize)).rounded(.up)) }

    init(view: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager,
         selectedSoundFontManager: SelectedSoundFontManager, favorites: Favorites, keyboard: Keyboard?,
         sampler: Sampler) {
        self.view = view
        self.searchBar = searchBar
        self.activePatchManager = activePatchManager
        self.showingSoundFont = activePatchManager.soundFont
        self.favorites = favorites
        self.keyboard = keyboard
        self.sampler = sampler
        super.init()

        view.register(PatchCell.self)
        view.dataSource = self
        view.delegate = self
        searchBar.delegate = self

        selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
        favorites.subscribe(self, notifier: favoritesChange)

        view.sectionIndexColor = .darkGray

//        for family in UIFont.familyNames.sorted() {
//            let names = UIFont.fontNames(forFamilyName: family)
//            print("Family: \(family) Font names: \(names)")
//        }

        let customFont = UIFont(name: "EurostileRegular", size: 20)!
        let defaultTextAttribs = [NSAttributedString.Key.font: customFont]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = defaultTextAttribs
    }
}

extension PatchesTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        showingSearchResults ? 1 : sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showingSearchResults ? filtered.count : min(patches.count - section * Self.sectionSize, Self.sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(for: indexPath), at: indexPath,
               with: getSoundFontPatch(for: indexPath))
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        showingSearchResults ? nil :
            [UITableView.indexSearch, "•"] +
            stride(from: PatchesTableViewManager.sectionSize, to: patches.count - 1,
                   by: PatchesTableViewManager.sectionSize).map { "\($0)" }
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
                hideSearchBar()
            }
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
        "\(section * PatchesTableViewManager.sectionSize)"
    }
}

// MARK: - UITableViewDelegate Protocol

extension PatchesTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) ->
        UISwipeActionsConfiguration? {
        return createLeadingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) ->
        UISwipeActionsConfiguration? {
        return createTrailingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) ->
        UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if !showingSearchResults {
            dismissSearchKeyboard()
            hideSearchBar()
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let soundFontPatch = getSoundFontPatch(for: indexPath)
        dismissSearchResults()
        let playSample = Settings[.playSample]
        if let favorite = favorites.getBy(soundFontPatch: soundFontPatch) {
            activePatchManager.setActive(.favorite(favorite: favorite), playSample: playSample)
        }
        else {
            activePatchManager.setActive(.normal(soundFontPatch: soundFontPatch), playSample: playSample)
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .lightText
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        header.backgroundView = HeaderView()
        header.backgroundView?.backgroundColor = .black
    }
}

private class HeaderView: UIView {
}

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
        else {
            dismissSearchResults()
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
            if showingSoundFont != new.soundFontPatch?.soundFont {
                os_log(.info, log: log, "new font")
                showingSoundFont = new.soundFontPatch?.soundFont
                reloadView()
            }
            else {
                os_log(.info, log: log, "same font")
                if old.soundFontPatch?.soundFont == showingSoundFont {
                    update(with: old.soundFontPatch)
                }
            }

            if let indexPath = update(with: new.soundFontPatch) {
                view.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                view.scrollToRow(at: indexPath, at: .none, animated: false)
            }

            hideSearchBar()
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
                        if let indexPath = self.getIndexPath(for: self.activePatchManager.soundFontPatch) {
                            self.view.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            self.view.scrollToRow(at: indexPath, at: .none, animated: false)
                        }
                    }
                    else if !self.showingSearchResults {
                        self.hideSearchBar()
                    }
                }
            }
        }
    }

    private func getFavorite(from event: FavoritesEvent) -> Favorite? {
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

        hideSearchBar()
    }

    private func getIndexPath(for soundFontPatch: SoundFontPatch?) -> IndexPath? {
        guard let soundFontPatch = soundFontPatch else { return nil }

        os_log(.info, log: log, "getIndexPath of '%s'", soundFontPatch.description)
        guard showingSoundFont == soundFontPatch.soundFont else {
            os_log(.info, "not showing in view")
            return nil
        }

        let patch = soundFontPatch.patch
        if showingSearchResults {
            os_log(.info, "showing search results")
            guard let row: Int = filtered.firstIndex(where: { $0.soundFontIndex == patch.soundFontIndex }) else {
                os_log(.info, "not found in search results")
                return nil
            }
            os_log(.info, "IndexPath(row: %d  section: %d)", row, 0)
            return IndexPath(row: row, section: 0)
        }

        let section = patch.soundFontIndex / Self.sectionSize
        let row = patch.soundFontIndex - Self.sectionSize * section
        os_log(.info, "IndexPath(row: %d  section: %d)", row, section)
        return IndexPath(row: row, section: section)
    }

    /**
     Obtain a Patch index for the given view IndexPath. This is the inverse of `indexPath(of:)`.

     - parameter indexPath: the IndexPath to convert
     - returns: Patch index
     */
    private func patchIndex(of indexPath: IndexPath) -> Int { indexPath.section * Self.sectionSize + indexPath.row }

    private func makeSoundFontPatch(for patch: Patch) -> SoundFontPatch {
        SoundFontPatch(soundFont: showingSoundFont!, patchIndex: patch.soundFontIndex)
    }

    private func isActive(soundFontPatch: SoundFontPatch) -> Bool {
        activePatchManager.soundFontPatch == soundFontPatch
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

    func hideSearchBar() {
        dismissSearchKeyboard()
        if !showingSearchResults && view.contentOffset.y <= searchBar.frame.size.height {
            os_log(.info, log: log, "hiding search bar")
            let view = self.view
            let contentOffset = CGPoint(x: 0, y: searchBar.frame.size.height)
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.3,
                delay: 0.0,
                options: [.curveEaseOut],
                animations: { view.contentOffset = contentOffset },
                completion: { _ in view.contentOffset = contentOffset })
        }
    }

    func selectActive() {
        os_log(.info, log: log, "selectActive")
        if let indexPath = getIndexPath(for: activePatchManager.soundFontPatch) {
            view.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            view.scrollToRow(at: indexPath, at: .none, animated: false)
            hideSearchBar()
        }
    }

    private func getActionImage(_ name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle(for: Self.self), compatibleWith: .none)
    }

    private func createFaveAction(cell: PatchCell, at indexPath: IndexPath,
                                  with soundFontPatch: SoundFontPatch) -> UIContextualAction {
        let lowestNote = keyboard?.lowestNote
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.favorites.add(soundFontPatch: soundFontPatch, keyboardLowestNote: lowestNote)
            self.update(cell: cell, at: indexPath, with: soundFontPatch)
            completionHandler(true)
        }
        action.image = getActionImage("Fave")
        action.backgroundColor = UIColor.orange
        return action
    }

    private func createUnfaveAction(cell: PatchCell, at indexPath: IndexPath,
                                    with soundFontPatch: SoundFontPatch) -> UIContextualAction {
        guard let favorite = favorites.getBy(soundFontPatch: soundFontPatch) else { fatalError() }
        let index = favorites.index(of: favorite)
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            if favorite == self.activePatchManager.favorite {
                self.activePatchManager.setActive(.normal(soundFontPatch: favorite.soundFontPatch))
            }
            self.favorites.remove(index: index, bySwiping: true)
            self.view.beginUpdates()
            self.update(cell: cell, at: indexPath, with: soundFontPatch)
            self.view.endUpdates()
            completionHandler(true)
        }
        action.image = getActionImage("Unfave")
        action.backgroundColor = UIColor.red
        return action
    }

    private func createEditAction(cell: PatchCell, at indexPath: IndexPath,
                                  with soundFontPatch: SoundFontPatch) -> UIContextualAction {
        guard let favorite = favorites.getBy(soundFontPatch: soundFontPatch) else { fatalError() }
        let action = UIContextualAction(style: .normal, title: nil) { _, _, completionHandler in
            self.favorites.beginEdit(favorite: favorite, view: cell)
            completionHandler(true)
        }
        action.image = getActionImage("Edit")
        action.backgroundColor = UIColor.orange
        return action
    }

    private func createLeadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: PatchCell = view.cellForRow(at: indexPath) else { return nil }
        let soundFontPatch = getSoundFontPatch(for: indexPath)
        let action = favorites.isFavored(soundFontPatch: soundFontPatch) ?
            createEditAction(cell: cell, at: indexPath, with: soundFontPatch) :
            createFaveAction(cell: cell, at: indexPath, with: soundFontPatch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = true
        return actions
    }

    private func createTrailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: PatchCell = view.cellForRow(at: indexPath) else { return nil }
        let soundFontPatch = getSoundFontPatch(for: indexPath)
        let actions = UISwipeActionsConfiguration(actions: favorites.isFavored(soundFontPatch: soundFontPatch) ?
            [createUnfaveAction(cell: cell, at: indexPath, with: soundFontPatch)] : [])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func getSoundFontPatch(for indexPath: IndexPath) -> SoundFontPatch {
        makeSoundFontPatch(for: showingSearchResults ? filtered[indexPath.row] : patches[patchIndex(of: indexPath)])
    }

    @discardableResult
    private func update(with soundFontPatch: SoundFontPatch?) -> IndexPath? {
        guard let indexPath = getIndexPath(for: soundFontPatch) else { return nil }
        update(at: indexPath, with: soundFontPatch!)
        return indexPath
    }

    @discardableResult
    private func update(with favorite: Favorite) -> IndexPath? {
        guard let indexPath = getIndexPath(for: favorite.soundFontPatch) else { return nil }
        update(at: indexPath, with: favorite)
        return indexPath
    }

    private func update(at indexPath: IndexPath, with soundFontPatch: SoundFontPatch) {
        if let cell: PatchCell = view.cellForRow(at: indexPath) {
            update(cell: cell, at: indexPath, with: soundFontPatch)
        }
    }

    private func update(at indexPath: IndexPath, with favorite: Favorite) {
        if let cell: PatchCell = view.cellForRow(at: indexPath) {
            update(cell: cell, at: indexPath, with: favorite)
        }
    }

    /**
     Update the given table cell with Patch state. NOTE: *all* PatchCell updates should be done via this routine
     instead of direct `cell.update` calls.

     - parameter cell: the cell to update
     - parameter patch: the Patch to use for the updating
     */
    @discardableResult
    private func update(cell: PatchCell, at indexPath: IndexPath, with soundFontPatch: SoundFontPatch) -> PatchCell {
        if let favorite = favorites.getBy(soundFontPatch: soundFontPatch) {
            return update(cell: cell, at: indexPath, with: favorite)
        }

        let active = isActive(soundFontPatch: soundFontPatch)
        cell.update(name: soundFontPatch.patch.name, isSelected: active, isActive: active, isFavorite: false)
        return cell
    }

    @discardableResult
    private func update(cell: PatchCell, at indexPath: IndexPath, with favorite: Favorite) -> PatchCell {
        let active = isActive(soundFontPatch: favorite.soundFontPatch)
        cell.update(name: favorite.name, isSelected: active, isActive: active, isFavorite: true)
        return cell
    }
}
