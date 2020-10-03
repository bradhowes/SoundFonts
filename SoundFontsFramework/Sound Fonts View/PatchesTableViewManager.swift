// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Number of sections we partition patches into
private let sectionSize = 20

/**
 Data source and delegate for the Patches UITableView.
 */
final class PatchesTableViewManager: NSObject {

    private lazy var log = Logging.logger("PatTVM")

    private let view: UITableView

    private let searchBar: UISearchBar
    private var lastSearchText: String?
    private let activePatchManager: ActivePatchManager
    private let soundFonts: SoundFonts
    private let favorites: Favorites
    private let keyboard: Keyboard?

    private var showingSoundFont: LegacySoundFont?
    private var viewPresets = [LegacyPatch]()
    private var searchPresets = [LegacyPatch]()

    init(view: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager, selectedSoundFontManager: SelectedSoundFontManager,
         soundFonts: SoundFonts, favorites: Favorites, keyboard: Keyboard?, infoBar: InfoBar) {
        self.view = view
        self.searchBar = searchBar
        self.activePatchManager = activePatchManager
        self.showingSoundFont = activePatchManager.soundFont
        self.soundFonts = soundFonts
        self.favorites = favorites
        self.keyboard = keyboard
        super.init()

        infoBar.addEventClosure(.editVisibility) { self.toggleVisibilityEditing() }

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

private extension Array where Element == LegacyPatch {
    subscript(indexPath: IndexPath) -> Element { self[indexPath.section * sectionSize + indexPath.row] }
}

private extension IndexPath {
    init(presetIndex: Int) {
        let section = presetIndex / sectionSize
        let row = presetIndex - section * sectionSize
        self.init(row: row, section: section)
    }

    var presetIndex: Int { section * sectionSize + row }
}

extension PatchesTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        showingSearchResults ? 1 : Int((Float(viewPresets.count) / Float(sectionSize)).rounded(.up))
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showingSearchResults ? searchPresets.count : min(viewPresets.count - section * sectionSize, sectionSize)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        updateView(cell: tableView.dequeueReusableCell(at: indexPath), at: indexPath, with: getViewPreset(at: indexPath))
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showingSearchResults { return nil }
        return [UITableView.indexSearch, "•"] + stride(from: sectionSize, to: viewPresets.count - 1, by: sectionSize).map { "\($0)" }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard index > 0 else {
            showSearchBar()
            return 0
        }

        dismissSearchKeyboard()
        return index - 1
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

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { isFavored(at: indexPath) == false }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if view.isEditing {
            setPresetVisibility(at: indexPath, state: true)
            return
        }

        let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath)
        dismissSearchResults()

        if let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch) {
            activePatchManager.setActive(favorite: favorite, playSample: settings.playSample)
        }
        else {
            activePatchManager.setActive(preset: soundFontAndPatch, playSample: settings.playSample)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if view.isEditing {
            setPresetVisibility(at: indexPath, state: false)
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

    private func updateViewPresets() {
        viewPresets = showingSoundFont?.patches ?? []
        view.reloadData()
    }

    private func showSearchBar() {
        guard searchBar.isFirstResponder == false else { return }
        DispatchQueue.main.async { UIView.animate(withDuration: 0.24) { self.view.contentOffset = CGPoint.zero } }
        searchBar.becomeFirstResponder()
        if let term = lastSearchText, !term.isEmpty {
            self.searchBar.text = term
            search(for: term)
        }
    }

    private func setPresetVisibility(at indexPath: IndexPath, state: Bool) {
        guard let soundFont = showingSoundFont else { return }
        let preset = viewPresets[indexPath]
        preset.isVisible = state
        soundFonts.setVisibility(key: soundFont.key, index: preset.soundFontIndex, state: state)
        // cell.setSelected(isVisible, animated: true)
    }

    private func toggleVisibilityEditing() {
        guard let soundFont = showingSoundFont else { return }
        if view.isEditing == false {
            os_log(.debug, log: log, "editing visibility table")
            viewPresets = soundFont.patches
            let insertions = viewPresets.enumerated()
                .filter { $0.1.isVisible == false }
                .map { IndexPath(presetIndex: $0.0) }
            view.performBatchUpdates {
                self.view.insertRows(at: insertions, with: .automatic)
            }
            completion: { _ in
                self.view.setEditing(true, animated: true)
                self.updateVisibilitySelections()
            }
        }
        else {
            os_log(.debug, log: log, "finished editing visibility table")
            let deletions = viewPresets.enumerated()
                .filter { $0.1.isVisible == false }
                .map { IndexPath(presetIndex: $0.0) }
            viewPresets = soundFont.patches.filter { $0.isVisible }
            view.performBatchUpdates {
                self.view.deleteRows(at: deletions, with: .automatic)
            }
            completion: { _ in
                self.view.setEditing(false, animated: true)
            }
        }
    }

    private func updateVisibilitySelections() {
        precondition(view.isEditing)
        guard let soundFont = showingSoundFont else { return }
        os_log(.debug, log: self.log, "updateVisibilitySelections")
        for (index, preset) in viewPresets.enumerated() {
            let indexPath = IndexPath(presetIndex: index)
            if preset.isVisible || isFavored(at: indexPath) {
                if !preset.isVisible {
                    soundFonts.setVisibility(key: soundFont.key, index: preset.soundFontIndex, state: true)
                }
                view.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        switch event {
        case let .active(old: old, new: new, playSample: _):
            os_log(.debug, log: log, "activePatchChange")
            view.performBatchUpdates({
                updateView(with: old.soundFontAndPatch)
                updateView(with: new.soundFontAndPatch)
            }, completion: { finished in
                guard finished else { return }
                self.selectActive(animated: false)
            })
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        os_log(.info, log: log, "selectedSoundFontChange")
        guard case let .changed(old: _, new: new) = event, showingSoundFont != new else { return }

        showingSoundFont = new
        updateViewPresets()

        if view.isEditing {
            updateVisibilitySelections()
            return
        }

        if activePatchManager.soundFont == new {
            selectActive(animated: false)
        }
        else if !showingSearchResults {
            view.layoutIfNeeded()
            hideSearchBar(animated: false)
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChange")
        switch event {
        case .restored:
            if let visibleRows = view.indexPathsForVisibleRows {
                view.reloadRows(at: visibleRows, with: .automatic)
            }
            else {
                view.reloadData()
            }

        default:
            if let favorite = event.favorite {
                os_log(.info, log: log, "updating due to favorite")
                view.beginUpdates()
                updateView(with: favorite)
                view.endUpdates()
            }
        }
    }

    private func getPresetIndexPath(for soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
        guard let soundFontAndPatch = soundFontAndPatch else { return nil }
        guard let soundFont = showingSoundFont, soundFont.key == soundFontAndPatch.soundFontKey else { return nil }
        let patch = soundFont.patches[soundFontAndPatch.patchIndex]
        if showingSearchResults {
            guard let row: Int = searchPresets.firstIndex(where: { $0.soundFontIndex == patch.soundFontIndex }) else { return nil }
            return IndexPath(row: row, section: 0)
        }

        guard let index = viewPresets.firstIndex(of: patch) else { return nil }
        return IndexPath(presetIndex: index)
    }

    private var showingSearchResults: Bool { searchBar.searchTerm != nil }

    private func dismissSearchResults() {
        os_log(.info, log: log, "dismissSearchResults")
        guard searchBar.text != nil else { return }
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

    private func hideSearchBar(animated: Bool) {
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
        os_log(.debug, log: log, "selectActive")
        guard let indexPath = getPresetIndexPath(for: activePatchManager.soundFontAndPatch) else { return }
        let visibleRows = view.indexPathsForVisibleRows
        if !(visibleRows?.contains(indexPath) ?? false) {
            os_log(.debug, log: log, "scrolling to selected row")
            // self.view.layoutIfNeeded() // Needed so that we have a valid view state for the following to have any effect
            // self.view.scrollToRow(at: indexPath, at: .none, animated: animated)
            view.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
        }
        hideSearchBar(animated: true)
    }

    private func isActive(_ preset: LegacyPatch) -> Bool {
        activePatchManager.active.soundFontAndPatch == makeSoundFontAndPatch(for: preset)
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
                self.activePatchManager.setActive(preset: favorite.soundFontAndPatch, playSample: false)
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
        guard let soundFont = showingSoundFont else { fatalError("internal inconsistency") }
        return UIContextualAction(tag: "Hide", color: .gray) { _, _, completionHandler in
            self.soundFonts.setVisibility(key: soundFont.key, index: patch.soundFontIndex, state: false)
            self.viewPresets.remove(at: indexPath.presetIndex)
            self.view.performBatchUpdates({
                self.view.deleteRows(at: [indexPath], with: .automatic)
            }, completion: { _ in
                if self.isActive(patch) {
                    self.activePatchManager.clearActive()
                }
            })
            completionHandler(true)
        }
    }

    private func createLeadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let patch = getViewPreset(at: indexPath)
        let action = isFavored(patch) ?
            createEditSwipeAction(at: indexPath, cell: cell, patch: patch) :
            createFaveSwipeAction(at: indexPath, cell: cell, patch: patch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = true
        return actions
    }

    private func createTrailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let patch = getViewPreset(at: indexPath)
        guard patch.isVisible else { return nil }
        let action = isFavored(patch) ?
            createUnfaveSwipeAction(at: indexPath, cell: cell, patch: patch) :
            createHideSwipeAction(at: indexPath, cell: cell, patch: patch)
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func getViewPreset(at indexPath: IndexPath) -> LegacyPatch {
        showingSearchResults ? searchPresets[indexPath] : viewPresets[indexPath]
    }

    private func makeSoundFontAndPatch(at index: IndexPath) -> SoundFontAndPatch {
        makeSoundFontAndPatch(for: getViewPreset(at: index))
    }

    private func makeSoundFontAndPatch(for patch: LegacyPatch) -> SoundFontAndPatch {
        guard let soundFont = showingSoundFont else { fatalError("internal inconsistency") }
        return soundFont.makeSoundFontAndPatch(for: patch)
    }

    private func isFavored(at indexPath: IndexPath) -> Bool {
        isFavored(getViewPreset(at: indexPath)) == false
    }

    private func isFavored(_ preset: LegacyPatch) -> Bool {
        favorites.isFavored(soundFontAndPatch: makeSoundFontAndPatch(for: preset)) == false
    }

    private func updateView(with soundFontAndPatch: SoundFontAndPatch?) {
        guard let indexPath = getPresetIndexPath(for: soundFontAndPatch),
              let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath, with: getViewPreset(at: indexPath))
    }

    private func updateView(with favorite: LegacyFavorite) {
        guard let indexPath = getPresetIndexPath(for: favorite.soundFontAndPatch),
              let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath, with: getViewPreset(at: indexPath))
    }

    @discardableResult
    private func updateView(cell: TableCell, at indexPath: IndexPath, with preset: LegacyPatch) -> TableCell {
        let soundFontAndPatch = makeSoundFontAndPatch(for: preset)
        let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch)
        let name = favorite?.name ?? preset.name
        if view.isEditing {
            cell.updateForVisibility(name: name, isFavorite: favorite != nil, isVisible: preset.isVisible)
        }
        else {
            cell.updateForPatch(name: name, isActive: soundFontAndPatch == activePatchManager.active.soundFontAndPatch, isFavorite: favorite != nil, isVisible: preset.isVisible)
        }
        return cell
    }
}
