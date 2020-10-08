// Copyright © 2018 Brad Howes. All rights reserved.
// swiftlint:disable file_length
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
    private let selectedSoundFontManager: SelectedSoundFontManager
    private let activePatchManager: ActivePatchManager
    private let soundFonts: SoundFonts
    private let favorites: Favorites
    private let keyboard: Keyboard?
    private let infoBar: InfoBar

    private var viewPresets = [Int]()
    private var searchPresets = [Int]()
    private var sectionRowCounts = [Int]()

    init(view: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager, selectedSoundFontManager: SelectedSoundFontManager,
         soundFonts: SoundFonts, favorites: Favorites, keyboard: Keyboard?, infoBar: InfoBar) {
        self.view = view
        self.searchBar = searchBar
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.soundFonts = soundFonts
        self.favorites = favorites
        self.keyboard = keyboard
        self.infoBar = infoBar
        super.init()

        infoBar.addEventClosure(.editVisibility, self.toggleVisibilityEditing)

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
        searchBar.delegate = self

        selectedSoundFontManager.subscribe(self, notifier: selectedSoundFontChange)
        activePatchManager.subscribe(self, notifier: activePatchChange)
        favorites.subscribe(self, notifier: favoritesChange)
        soundFonts.subscribe(self, notifier: soundFontsChange)

        view.sectionIndexColor = .darkGray

        let customFont = UIFont(name: "EurostileRegular", size: 20)!
        let defaultTextAttribs = [NSAttributedString.Key.font: customFont, NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = defaultTextAttribs

        updateViewPresets()
    }
}

private extension Array {
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
        showingSearchResults ? 1 : sectionRowCounts.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let value = showingSearchResults ? searchPresets.count : sectionRowCounts[section]
        os_log(.debug, log: log, "section %d number of rows: %d", section, value)
        return value
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        updateView(cell: tableView.dequeueReusableCell(at: indexPath), at: indexPath)
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
        os_log(.debug, log: log, "sectionForSectionIndex %d - %d", index, index - 1)
        return index - 1
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

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        !(view.isEditing && isFavored(at: indexPath))
    }

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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search(for: searchBar.searchTerm ?? "")
    }
}

// MARK: - Private

extension PatchesTableViewManager {

    private func dismissSearchKeyboard() {
        guard searchBar.isFirstResponder && searchBar.canResignFirstResponder else { return }
        searchBar.resignFirstResponder()
    }

    private func updateViewPresets() {
        let source = selectedSoundFontManager.selected?.patches ?? []
        viewPresets = source.filter { $0.isVisible == true || view.isEditing } .map { $0.soundFontIndex }
        updateSectionRowCounts()
        view.reloadData()
    }

    private func updateSectionRowCounts() {
        let numFullSections = viewPresets.count / sectionSize
        sectionRowCounts = [Int](repeating: sectionSize, count: numFullSections)
        sectionRowCounts.append(viewPresets.count - numFullSections * sectionSize)
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
        guard let soundFont = selectedSoundFontManager.selected else { return }
        let preset = soundFont.patches[viewPresets[indexPath]]
        soundFonts.setVisibility(key: soundFont.key, index: preset.soundFontIndex, state: state)
    }

    private func toggleVisibilityEditing(_ sender: AnyObject) {
        guard let soundFont = selectedSoundFontManager.selected else { return }
        let button = sender as? UIButton
        button?.tintColor = view.isEditing ? .systemTeal : .systemYellow
        if view.isEditing == false {
            beginVisibilityEditing(for: soundFont)
        }
        else {
            endVisibilityEditing(for: soundFont)
        }
    }

    private func beginVisibilityEditing(for soundFont: LegacySoundFont) {
        viewPresets = soundFont.patches.map { $0.soundFontIndex }
        let insertions = viewPresets.enumerated()
            .filter { soundFont.patches[$0.1].isVisible == false }
            .map { IndexPath(presetIndex: $0.0) }
        view.performBatchUpdates {
            self.view.insertRows(at: insertions, with: .automatic)
            for index in insertions { self.sectionRowCounts[index.section] += 1 }
        }
        completion: { _ in
            self.view.setEditing(true, animated: true)
            self.updateVisibilitySelections(soundFont: soundFont)
        }
    }

    private func endVisibilityEditing(for soundFont: LegacySoundFont) {
        infoBar.hideButtons()
        let deletions = viewPresets.enumerated()
            .filter { soundFont.patches[$0.1].isVisible == false }
            .map { IndexPath(presetIndex: $0.0) }
        view.performBatchUpdates {
            self.view.deleteRows(at: deletions, with: .automatic)
            for index in deletions { self.sectionRowCounts[index.section] -= 1 }
        }
        completion: { _ in
            self.view.setEditing(false, animated: true)
            self.viewPresets = soundFont.patches.filter { $0.isVisible == true } .map { $0.soundFontIndex }
            self.view.reloadSections(IndexSet(stride(from: 0, to: self.sectionRowCounts.count, by: 1)), with: .automatic)
        }
    }

    private func updateVisibilitySelections(soundFont: LegacySoundFont) {
        precondition(view.isEditing)
        os_log(.debug, log: self.log, "updateVisibilitySelections")
        for (index, presetIndex) in viewPresets.enumerated() {
            let indexPath = IndexPath(presetIndex: index)
            let preset = soundFont.patches[presetIndex]
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
        guard case let .changed(old: old, new: new) = event else { return }
        os_log(.info, log: log, "selectedSoundFontChange - old: '%s' new: '%s'", old?.displayName ?? "N/A", new?.displayName ?? "N/A")
        updateViewPresets()
        if view.isEditing {
            if let soundFont = new {
                updateVisibilitySelections(soundFont: soundFont)
            }
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
            os_log(.info, log: log, "favoritesChange - restored")
            if let visibleRows = view.indexPathsForVisibleRows {
                view.reloadRows(at: visibleRows, with: .automatic)
            }
            else {
                view.reloadData()
            }

        default:
            os_log(.info, log: log, "favoritesChange - default")
            if let favorite = event.favorite {
                os_log(.info, log: log, "updating due to favorite")
                view.beginUpdates()
                updateView(with: favorite)
                view.endUpdates()
            }
        }
    }

    private func soundFontsChange(_ event: SoundFontsEvent) {
        switch event {
        case let .unhidPresets(font: soundFont):
            if soundFont == selectedSoundFontManager.selected {
                updateViewPresets()
            }

        case .restored:
            if viewPresets.isEmpty {
                updateViewPresets()
                selectActive(animated: false)
                hideSearchBar(animated: false)
            }

        default:
            break
        }
    }

    private func getPresetIndexPath(for soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
        guard let soundFontAndPatch = soundFontAndPatch else { return nil }
        guard let soundFont = selectedSoundFontManager.selected, soundFont.key == soundFontAndPatch.soundFontKey else { return nil }
        if showingSearchResults {
            guard let row: Int = searchPresets.firstIndex(where: { $0 == soundFontAndPatch.patchIndex }) else { return nil }
            return IndexPath(row: row, section: 0)
        }

        guard let index = viewPresets.firstIndex(of: soundFontAndPatch.patchIndex) else { return nil }
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
        guard let soundFont = selectedSoundFontManager.selected else { return }
        lastSearchText = searchTerm
        searchPresets = viewPresets.filter { soundFont.patches[$0].name.localizedCaseInsensitiveContains(searchTerm) }
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
            view.selectRow(at: indexPath, animated: animated, scrollPosition: .middle)
        }
        hideSearchBar(animated: true)
    }

    private func isActive(_ soundFontAndPatch: SoundFontAndPatch) -> Bool {
        activePatchManager.active.soundFontAndPatch == soundFontAndPatch
    }

    private func createFaveSwipeAction(at indexPath: IndexPath, cell: TableCell, soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Fave", color: .orange) { _, _, completionHandler in
            guard let soundFont = self.soundFonts.getBy(key: soundFontAndPatch.soundFontKey) else {
                completionHandler(false)
                return
            }

            let patch = soundFont.patches[soundFontAndPatch.patchIndex]
            self.favorites.add(name: patch.name, soundFontAndPatch: soundFontAndPatch, keyboardLowestNote: self.keyboard?.lowestNote)
            DispatchQueue.main.async {
                self.view.beginUpdates()
                self.updateView(cell: cell, at: indexPath)
                self.view.endUpdates()
            }
            completionHandler(true)
        }
    }

    private func createUnfaveSwipeAction(at indexPath: IndexPath, cell: TableCell, soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Unfave", color: .red) { _, view, completionHandler in
            guard let favorite = self.favorites.getBy(soundFontAndPatch: soundFontAndPatch) else {
                completionHandler(false)
                return
            }

            let index = self.favorites.index(of: favorite)
            if favorite == self.activePatchManager.favorite {
                self.activePatchManager.setActive(preset: favorite.soundFontAndPatch, playSample: false)
            }

            self.favorites.remove(index: index, bySwiping: true)
            DispatchQueue.main.async {
                self.view.beginUpdates()
                self.updateView(cell: cell, at: indexPath)
                self.view.endUpdates()
            }
            completionHandler(true)
        }
    }

    private func createEditSwipeAction(at indexPath: IndexPath, cell: TableCell, soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Edit", color: .orange) { _, view, completionHandler in
            guard let favorite = self.favorites.getBy(soundFontAndPatch: soundFontAndPatch) else {
                completionHandler(false)
                return
            }

            var rect = self.view.rectForRow(at: indexPath)
            rect.size.width = 240.0
            let position = self.favorites.index(of: favorite)
            let config = FavoriteEditor.Config(indexPath: IndexPath(item: position, section: 0), view: view, rect: view.bounds, favorite: favorite,
                                               currentLowestNote: self.keyboard?.lowestNote, completionHandler: completionHandler,
                                               soundFonts: self.soundFonts,
                                               soundFontAndPatch: soundFontAndPatch)

            self.favorites.beginEdit(config: config)
        }
    }

    private func createHideSwipeAction(at indexPath: IndexPath, cell: TableCell, soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Hide", color: .gray) { _, _, completionHandler in
            self.soundFonts.setVisibility(key: soundFontAndPatch.soundFontKey, index: soundFontAndPatch.patchIndex, state: false)
            self.viewPresets.remove(at: indexPath.presetIndex)
            self.view.performBatchUpdates({
                self.view.deleteRows(at: [indexPath], with: .automatic)
                self.sectionRowCounts[indexPath.section] -= 1
            }, completion: { _ in
                self.updateSectionRowCounts()
                self.view.reloadSections(IndexSet(stride(from: 0, to: self.sectionRowCounts.count, by: 1)), with: .automatic)
            })
            completionHandler(true)
        }
    }

    private func createLeadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath)
        return makeSwipeActionConfiguration(action: isFavored(soundFontAndPatch) ?
                                                createEditSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch) :
                                                createFaveSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch))
    }

    private func createTrailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath)
        return makeSwipeActionConfiguration(action: isFavored(soundFontAndPatch) ?
                                                createUnfaveSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch) :
                                                createHideSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch))
    }

    private func makeSwipeActionConfiguration(action: UIContextualAction) -> UISwipeActionsConfiguration {
        let actions = UISwipeActionsConfiguration(actions: [action])
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }

    private func getViewPresetIndex(at indexPath: IndexPath) -> Int {
        showingSearchResults ? searchPresets[indexPath] : viewPresets[indexPath]
    }

    private func makeSoundFontAndPatch(at indexPath: IndexPath) -> SoundFontAndPatch {
        guard let soundFont = selectedSoundFontManager.selected else { fatalError("internal inconsistency") }
        return soundFont.makeSoundFontAndPatch(at: getViewPresetIndex(at: indexPath))
    }

    private func isFavored(at indexPath: IndexPath) -> Bool {
        isFavored(makeSoundFontAndPatch(at: indexPath))
    }

    private func isFavored(_ soundFontAndPatch: SoundFontAndPatch) -> Bool {
        favorites.isFavored(soundFontAndPatch: soundFontAndPatch)
    }

    private func updateView(with soundFontAndPatch: SoundFontAndPatch?) {
        guard let indexPath = getPresetIndexPath(for: soundFontAndPatch),
              let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath)
    }

    private func updateView(with favorite: LegacyFavorite) {
        guard let indexPath = getPresetIndexPath(for: favorite.soundFontAndPatch),
              let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath)
    }

    @discardableResult
    private func updateView(cell: TableCell, at indexPath: IndexPath) -> TableCell {
        guard let soundFont = selectedSoundFontManager.selected else { fatalError() }
        let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath)
        let favorite = favorites.getBy(soundFontAndPatch: soundFontAndPatch)
        let preset = soundFont.patches[getViewPresetIndex(at: indexPath)]
        let name = favorite?.name ?? preset.name
        cell.updateForPatch(name: name, isActive: soundFontAndPatch == activePatchManager.active.soundFontAndPatch, isFavorite: favorite != nil, isEditing: view.isEditing)
        return cell
    }
}
