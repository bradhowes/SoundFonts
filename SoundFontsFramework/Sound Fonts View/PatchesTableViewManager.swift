// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Data source and delegate for the Patches UITableView.
 */
final class PatchesTableViewManager: NSObject {

    private lazy var log = Logging.logger("PatTVM")

    /// Number of sections we partition patches into
    private let sectionSize = 20

    private let view: UITableView
    private let visibilityView: UITableView

    private let searchBar: UISearchBar
    private var lastSearchText: String?
    private let activePatchManager: ActivePatchManager
    private let soundFonts: SoundFonts
    private let favorites: Favorites
    private let keyboard: Keyboard?
    private let sampler: Sampler

    private var showingSoundFont: LegacySoundFont?
    private var viewPresets = [LegacyPatch]()
    private var visibilityPresets = [LegacyPatch]()
    private var searchPresets = [LegacyPatch]()

    private func sectionCount(source: [LegacyPatch]) -> Int { Int((Float(source.count) / Float(sectionSize)).rounded(.up)) }

    init(view: UITableView, visibilityView: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager,
         selectedSoundFontManager: SelectedSoundFontManager, soundFonts: SoundFonts, favorites: Favorites, keyboard: Keyboard?,
         sampler: Sampler, infoBar: InfoBar) {
        self.view = view
        self.visibilityView = visibilityView
        self.searchBar = searchBar
        self.activePatchManager = activePatchManager
        self.showingSoundFont = activePatchManager.soundFont
        self.soundFonts = soundFonts
        self.favorites = favorites
        self.keyboard = keyboard
        self.sampler = sampler
        super.init()

        settings.showHiddenPresets = false
        visibilityPresets = showingSoundFont?.patches ?? []
        viewPresets = visibilityPresets.filter { $0.isVisible }

        infoBar.addEventClosure(.editVisibility) { self.toggleVisibilityEditing() }

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
        searchBar.delegate = self

        visibilityView.register(TableCell.self)
        visibilityView.dataSource = self
        visibilityView.delegate = self

        selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
        favorites.subscribe(self, notifier: favoritesChange)

        view.sectionIndexColor = .darkGray

        let customFont = UIFont(name: "EurostileRegular", size: 20)!
        let defaultTextAttribs = [NSAttributedString.Key.font: customFont]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = defaultTextAttribs
    }

    private func toggleVisibilityEditing() {
        if view.isHidden == false {
            os_log(.debug, log: log, "showing visibility")
            visibilityView.setEditing(true, animated: true)
            view.alpha = 1.0
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0.0, options: [], animations: {
                self.view.alpha = 0.0
            }, completion: { _ in
                self.view.isHidden = true
                self.view.alpha = 1.0
            })

            for (index, preset) in visibilityPresets.enumerated() {
                let section = index / sectionSize
                let row = index - sectionSize * section
                let indexPath = IndexPath(row: row, section: section)
                let isFavorite = favorites.getBy(soundFontAndPatch: makeSoundFontAndPatch(for: preset)) != nil
                if preset.isVisible || isFavorite {
                    os_log(.debug, log: log, "selecting row %d", index)
                    preset.isVisible = true
                    visibilityView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
            }
        }
        else {
            viewPresets = visibilityPresets.filter { $0.isVisible }
            self.view.isHidden = false
            view.alpha = 0.0
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0.0, options: [], animations: {
                self.view.alpha = 1.0
                self.visibilityView.setEditing(false, animated: true)
            }, completion: { _ in
                self.view.alpha = 1.0
                self.view.reloadData()
            })
        }
    }
}

extension PatchesTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        showingSearchResults ? 1 : sectionCount(source: tableView == view ? viewPresets : visibilityPresets)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.view {
            return showingSearchResults ? searchPresets.count : min(viewPresets.count - section * sectionSize, sectionSize)
        }
        return min(visibilityPresets.count - section * sectionSize, sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == view {
            return updateView(cell: tableView.dequeueReusableCell(for: indexPath), at: indexPath, with: getViewPreset(for: indexPath))
        }
        else {
            return updateVisibility(cell: tableView.dequeueReusableCell(for: indexPath), at: indexPath, with: getVisibilityPreset(for: indexPath))
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !showingSearchResults else { return nil }
        if tableView == view {
            return [UITableView.indexSearch, "•"] + stride(from: sectionSize, to: viewPresets.count - 1, by: sectionSize).map { "\($0)" }
        }
        return [UITableView.indexSearch, "•"] + stride(from: sectionSize, to: visibilityPresets.count - 1, by: sectionSize).map { "\($0)" }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {

            // Going to show the search bar. We first tell UITableView to show the 0 section which shows the first
            // patch. We then have the UITableView reveal the search bar by updating the contentOffset in an animation.
            // This is done in an async block on the main thread so that it happens *after* the movement to the 0
            // section. *HACK*
            //
            if !self.searchBar.isFirstResponder {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.24) { self.view.contentOffset = CGPoint.zero }
                }
                self.searchBar.becomeFirstResponder()
                if let term = lastSearchText, !term.isEmpty {
                    self.searchBar.text = term
                    search(for: term)
                }
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
        guard tableView == view else { return nil }
        return createLeadingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard tableView == view else { return nil }
        return createTrailingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle { .none }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard tableView == visibilityView else { return false }
        return favorites.getBy(soundFontAndPatch: makeSoundFontAndPatch(for: getVisibilityPreset(for: indexPath))) == nil
    }

//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        guard !view.isEditing else { return indexPath }
//        if !showingSearchResults { dismissSearchKeyboard() }
//        return indexPath
//    }
//

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == visibilityView {
            guard let cell = tableView.cellForRow(at: indexPath) as? TableCell else { return }
            let patch = getVisibilityPreset(for: indexPath)
            patch.isVisible = !patch.isVisible
            cell.setSelected(patch.isVisible, animated: true)
            os_log(.debug, log: log, "didSelect %s %d", patch.name, patch.isVisible)
            return
        }

        let patch = getViewPreset(for: indexPath)
        dismissSearchResults()
        let playSample = settings.playSample
        let soundFontAndPatch = makeSoundFontAndPatch(for: patch)
        if let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch) {
            activePatchManager.setActive(.favorite(favorite: favorite), playSample: playSample)
        }
        else {
            activePatchManager.setActive(.normal(soundFontAndPatch: soundFontAndPatch), playSample: playSample)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == visibilityView {
            guard let cell = tableView.cellForRow(at: indexPath) as? TableCell else { return }
            let patch = getVisibilityPreset(for: indexPath)
            patch.isVisible = !patch.isVisible
            cell.setSelected(patch.isVisible, animated: true)
            os_log(.debug, log: log, "didDeselect %s %d", patch.name, patch.isVisible)
            return
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .systemTeal
        header.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        header.backgroundView = UIView()
        header.backgroundView?.backgroundColor = .black
    }
}

extension PatchesTableViewManager: UISearchBarDelegate {

    private func dismissSearchKeyboard() {
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
        let searchTerm = searchBar.searchTerm ?? ""
        search(for: searchTerm)
    }
}

// MARK: - Private

extension PatchesTableViewManager {

//    private func reloadView() {
//        if let searchTerm = searchBar.searchTerm {
//            search(for: searchTerm)
//        }
//        else {
//            view.reloadData()
//        }
//    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        os_log(.info, log: log, "activePatchChange")
        switch event {
        case let .active(old: old, new: new, playSample: _):
            view.performBatchUpdates({
                update(with: old.soundFontAndPatch)
                update(with: new.soundFontAndPatch)
            }, completion: { finished in
                if finished {
                    self.selectActive(animated: false)
                    if !self.showingSearchResults {
                        self.view.layoutIfNeeded()
                        self.hideSearchBar(animated: true)
                    }
                }
            })
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        guard case let .changed(old: _, new: new) = event, showingSoundFont != new else { return }

        showingSoundFont = new
        visibilityPresets = showingSoundFont?.patches ?? []
        visibilityView.reloadData()
        viewPresets = visibilityPresets.filter { $0.isVisible }
        view.reloadData()

        if activePatchManager.soundFont == new {
            selectActive(animated: false)
        }
        else if !showingSearchResults {
            view.layoutIfNeeded()
            hideSearchBar(animated: true)
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChange")
        switch event {
        case .restored:
            if let visibleRows = view.indexPathsForVisibleRows {
                view.reloadRows(at: visibleRows, with: .automatic)
            }

        default:
            if let favorite = event.favorite {
                os_log(.info, log: log, "updating due to favorite")
                view.beginUpdates()
                update(with: favorite)
                view.endUpdates()
            }
        }
    }

    private func getPresetIndexPath(for soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
        guard let soundFontAndPatch = soundFontAndPatch else { return nil }
        guard showingSoundFont?.key == soundFontAndPatch.soundFontKey else { return nil }
        guard let patch = activePatchManager.resolveToPatch(soundFontAndPatch) else { return nil }
        if showingSearchResults {
            os_log(.info, "showing search results")
            guard let row: Int = searchPresets.firstIndex(where: { $0.soundFontIndex == patch.soundFontIndex }) else {
                os_log(.info, "not found in search results")
                return nil
            }
            os_log(.info, "IndexPath(row: %d  section: %d)", row, 0)
            return IndexPath(row: row, section: 0)
        }

        guard let index = viewPresets.firstIndex(of: patch) else { return nil }
        let section = index / sectionSize
        let row = index - sectionSize * section
        os_log(.info, "IndexPath(row: %d  section: %d)", row, section)
        return IndexPath(row: row, section: section)
    }

    private func patchIndex(of indexPath: IndexPath) -> Int { indexPath.section * sectionSize + indexPath.row }

    private func makeSoundFontAndPatch(for patch: LegacyPatch) -> SoundFontAndPatch {
        SoundFontAndPatch(soundFontKey: showingSoundFont!.key, patchIndex: patch.soundFontIndex)
    }

    private var showingSearchResults: Bool { searchBar.searchTerm != nil }

    private func dismissSearchResults() {
        os_log(.info, log: log, "dismissSearchResults")
        searchBar.text = nil
        searchPresets.removeAll()
        view.reloadData()
        dismissSearchKeyboard()
    }

    private func search(for searchTerm: String) {
        os_log(.info, log: log, "search - '%s'", searchTerm)
        lastSearchText = searchTerm
        searchPresets = viewPresets.filter { $0.name.localizedCaseInsensitiveContains(searchTerm) }
        os_log(.info, log: log, "found %d matches", searchPresets.count)
        view.reloadData()
    }

    func hideSearchBar(animated: Bool) {
        dismissSearchKeyboard()
        if showingSearchResults || view.contentOffset.y > searchBar.frame.size.height * 2 { return }
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
        if let indexPath = getPresetIndexPath(for: activePatchManager.soundFontAndPatch) {
            let visibleRows = view.indexPathsForVisibleRows
            if !(visibleRows?.contains(indexPath) ?? true) {
                self.view.layoutIfNeeded() // Needed so that we have a valid view state for the following to have any effect
                self.view.scrollToRow(at: indexPath, at: .none, animated: animated)
                self.view.selectRow(at: indexPath, animated: animated, scrollPosition: .none)
            }
            self.hideSearchBar(animated: true)
        }
    }

    private func createFaveSwipeAction(at: IndexPath, cell: TableCell, patch: LegacyPatch) -> UIContextualAction {
        let lowestNote = keyboard?.lowestNote
        return UIContextualAction(tag: "Fave", color: .orange) { _, _, completionHandler in
            self.favorites.add(name: patch.name, soundFontAndPatch: self.makeSoundFontAndPatch(for: patch), keyboardLowestNote: lowestNote)
            DispatchQueue.main.async {
                self.view.beginUpdates()
                self.updateView(cell: cell, at: at, with: patch)
                self.view.endUpdates()
            }
            completionHandler(true)
        }
    }

    private func createUnfaveSwipeAction(at: IndexPath, cell: TableCell, patch: LegacyPatch) -> UIContextualAction {
        guard let favorite = favorites.getBy(soundFontAndPatch: makeSoundFontAndPatch(for: patch)) else { fatalError() }
        let index = favorites.index(of: favorite)
        return UIContextualAction(tag: "Unfave", color: .red) { _, view, completionHandler in
            if favorite == self.activePatchManager.favorite {
                self.activePatchManager.setActive(.normal(soundFontAndPatch: favorite.soundFontAndPatch), playSample: false)
            }
            self.favorites.remove(index: index, bySwiping: true)
            DispatchQueue.main.async {
                self.view.beginUpdates()
                self.updateView(cell: cell, at: at, with: patch)
                self.view.endUpdates()
            }
            completionHandler(true)
        }
    }

    private func createEditSwipeAction(at: IndexPath, cell: TableCell, patch: LegacyPatch) -> UIContextualAction {
        guard let favorite = favorites.getBy(soundFontAndPatch: makeSoundFontAndPatch(for: patch)) else { fatalError() }
        return UIContextualAction(tag: "Edit", color: .orange) { _, view, completionHandler in
            var rect = self.view.rectForRow(at: at)
            rect.size.width = 240.0
            let position = self.favorites.index(of: favorite)
            let config = FavoriteEditor.Config(indexPath: IndexPath(item: position, section: 0), view: view, rect: view.bounds, favorite: favorite,
                                               currentLowestNote: self.keyboard?.lowestNote, completionHandler: completionHandler, soundFont: self.showingSoundFont!, patch: patch)
            self.favorites.beginEdit(config: config)
        }
    }

    private func createHideSwipeAction(at indexPath: IndexPath, cell: TableCell, patch: LegacyPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Hide", color: .gray) { _, _, completionHandler in
            self.soundFonts.hidePreset(key: self.showingSoundFont!.key, index: patch.soundFontIndex)
            self.view.performBatchUpdates({
                self.viewPresets.remove(at: self.patchIndex(of: indexPath))
            }, completion: { _ in
                if self.activePatchManager.active.soundFontAndPatch == self.makeSoundFontAndPatch(for: patch) {
                    self.activePatchManager.setActive(.none, playSample: false)
                }
            })
            completionHandler(true)
        }
    }

    private func createLeadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let patch = getViewPreset(for: indexPath)
        let action = favorites.isFavored(soundFontAndPatch: makeSoundFontAndPatch(for: patch)) ?
            createEditSwipeAction(at: indexPath, cell: cell, patch: patch) :
            createFaveSwipeAction(at: indexPath, cell: cell, patch: patch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func createTrailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let patch = getViewPreset(for: indexPath)
        guard patch.isVisible else { return nil }
        let action = favorites.isFavored(soundFontAndPatch: makeSoundFontAndPatch(for: patch)) ?
            createUnfaveSwipeAction(at: indexPath, cell: cell, patch: patch) :
            createHideSwipeAction(at: indexPath, cell: cell, patch: patch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func getViewPreset(for indexPath: IndexPath) -> LegacyPatch { showingSearchResults ? searchPresets[indexPath.row] : viewPresets[patchIndex(of: indexPath)] }
    private func getVisibilityPreset(for indexPath: IndexPath) -> LegacyPatch { visibilityPresets[patchIndex(of: indexPath)] }

    private func update(with soundFontAndPatch: SoundFontAndPatch?) {
        guard let indexPath = getPresetIndexPath(for: soundFontAndPatch), let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath, with: getViewPreset(for: indexPath))
    }

    private func update(with favorite: LegacyFavorite) {
        guard let indexPath = getPresetIndexPath(for: favorite.soundFontAndPatch), let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath, with: getViewPreset(for: indexPath))
    }

    @discardableResult
    private func updateVisibility(cell: TableCell, at indexPath: IndexPath, with patch: LegacyPatch) -> TableCell {
        let soundFontAndPatch = makeSoundFontAndPatch(for: patch)
        let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch)
        let name = favorite?.name ?? patch.name
        cell.updateForEditing(name: name, isFavorite: favorite != nil, isVisible: patch.isVisible)
        return cell
    }

    @discardableResult
    private func updateView(cell: TableCell, at indexPath: IndexPath, with patch: LegacyPatch) -> TableCell {
        let soundFontAndPatch = makeSoundFontAndPatch(for: patch)
        let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch)
        let name = favorite?.name ?? patch.name
        if view.isEditing {
            os_log(.debug, log: log, "updateForEditing %s %d/%d %d", name, indexPath.section, indexPath.row, patch.isVisible)
            cell.updateForEditing(name: name, isFavorite: favorite != nil, isVisible: patch.isVisible)
        }
        else {
            os_log(.debug, log: log, "updateForPatch %s %d/%d %d", name, indexPath.section, indexPath.row, patch.isVisible)
            cell.updateForPatch(name: name, isActive: soundFontAndPatch == activePatchManager.active.soundFontAndPatch, isFavorite: favorite != nil,
                                isVisible: patch.isVisible)
        }
        return cell
    }
}
