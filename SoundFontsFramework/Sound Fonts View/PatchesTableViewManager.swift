// Copyright © 2018 Brad Howes. All rights reserved.
import UIKit
import os

/// Number of sections we partition patches into
private let sectionSize = 20

private enum Slot: Equatable {
    case preset(index: Int)
    case favorite(key: LegacyFavorite.Key)
}

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
    private let delay: Delay?
    private let reverb: Reverb?
    private let infoBar: InfoBar

    private var viewSlots = [Slot]()
    private var searchSlots = [Slot]()
    private var sectionRowCounts = [Int]()

    init(view: UITableView, searchBar: UISearchBar, activePatchManager: ActivePatchManager,
         selectedSoundFontManager: SelectedSoundFontManager, soundFonts: SoundFonts, favorites: Favorites,
         keyboard: Keyboard?, infoBar: InfoBar, delay: Delay?, reverb: Reverb?) {
        self.view = view
        self.searchBar = searchBar
        self.selectedSoundFontManager = selectedSoundFontManager
        self.activePatchManager = activePatchManager
        self.soundFonts = soundFonts
        self.favorites = favorites
        self.keyboard = keyboard
        self.delay = delay
        self.reverb = reverb
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
        let defaultTextAttributes = [NSAttributedString.Key.font: customFont,
                                     NSAttributedString.Key.foregroundColor: UIColor.systemTeal]
        UITextField.appearance().defaultTextAttributes = defaultTextAttributes

        updateViewPresets()
    }
}

private extension IndexPath {
    init(slotIndex: Int) {
        let section = slotIndex / sectionSize
        self.init(row: slotIndex - section * sectionSize, section: section)
    }

    var slotIndex: Int { section * sectionSize + row }
}

private extension Array where Element == Slot {
    subscript(indexPath: IndexPath) -> Element { self[indexPath.slotIndex] }
}

private extension Array where Element == Slot {
    func findFavoriteKey(_ key: LegacyFavorite.Key) -> Int? {
        for (index, slot) in self.enumerated() {
            if case let .favorite(slotKey) = slot, slotKey == key {
                return index
            }
        }
        return nil
    }

    func findPresetIndex(_ presetIndex: Int) -> Int? {
        for (index, slot) in self.enumerated() {
            if case let .preset(slotIndex) = slot, slotIndex == presetIndex {
                return index
            }
        }
        return nil
    }
}

// MARK: - UITableViewDataSource Protocol
extension PatchesTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        showingSearchResults ? 1 : sectionRowCounts.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        showingSearchResults ? searchSlots.count : sectionRowCounts[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableCell = tableView.dequeueReusableCell(at: indexPath)
        updateView(cell: cell, at: indexPath)
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showingSearchResults { return nil }
        return [UITableView.indexSearch, "•"] + stride(from: sectionSize, to: viewSlots.count - 1,
                                                         by: sectionSize).map { "\($0)" }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {
            showSearchBar()
            return 0
        }

        dismissSearchKeyboard()
        return index - 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 0.0 : 18.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "\(section * sectionSize)"
    }
}

// MARK: - UITableViewDelegate Protocol

extension PatchesTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        leadingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        trailingSwipeActions(at: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        switch viewSlots[indexPath.slotIndex] {
        case .favorite: return 1
        case .preset: return 0
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if view.isEditing {
            setSlotVisibility(at: indexPath, state: true)
            return
        }

        dismissSearchResults()

        switch viewSlots[indexPath.slotIndex] {
        case let .preset(presetIndex): selectPreset(presetIndex)
        case let .favorite(key): activePatchManager.setActive(favorite: favorites.getBy(key: key),
                                                              playSample: Settings.shared.playSample)
        }
    }

    private func withSoundFont<T>(_ closure: (LegacySoundFont) -> T?) -> T? {
        guard let soundFont = selectedSoundFontManager.selected else { return nil }
        return closure(soundFont)
    }

    private func selectPreset(_ presetIndex: Int) {
        withSoundFont { soundFont in
            let soundFontAndPatch = SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: presetIndex)
            activePatchManager.setActive(preset: soundFontAndPatch, playSample: Settings.shared.playSample)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard view.isEditing else { return }
        setSlotVisibility(at: indexPath, state: false)
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

extension PatchesTableViewManager {

    private func showSearchBar() {
        guard searchBar.isFirstResponder == false else { return }
        DispatchQueue.main.async { UIView.animate(withDuration: 0.24) { self.view.contentOffset = CGPoint.zero } }
        searchBar.becomeFirstResponder()
        if let term = lastSearchText, !term.isEmpty {
            self.searchBar.text = term
            search(for: term)
        }
    }

    private func dismissSearchKeyboard() {
        guard searchBar.isFirstResponder && searchBar.canResignFirstResponder else { return }
        searchBar.resignFirstResponder()
    }

    private func updateViewPresets() {
        let source = selectedSoundFontManager.selected?.patches ?? []
        viewSlots.removeAll()
        for (index, preset) in source.enumerated() {
            if preset.presetConfig.isVisible || view.isEditing {
                viewSlots.append(.preset(index: index))
            }
            for favoriteKey in preset.favorites {
                let favorite = favorites.getBy(key: favoriteKey)
                if favorite.presetConfig.isVisible || view.isEditing {
                    viewSlots.append(.favorite(key: favoriteKey))
                }
            }
        }

        updateSectionRowCounts(reload: false)
        view.reloadData()
    }

    private func updateSectionRowCounts(reload: Bool) {
        let numFullSections = viewSlots.count / sectionSize
        sectionRowCounts = [Int](repeating: sectionSize, count: numFullSections)
        sectionRowCounts.append(viewSlots.count - numFullSections * sectionSize)
        if reload {
            view.reloadSections(IndexSet(stride(from: 0, to: self.sectionRowCounts.count, by: 1)), with: .none)
        }
    }

    private func setSlotVisibility(at indexPath: IndexPath, state: Bool) {
        guard let soundFont = selectedSoundFontManager.selected else { return }
        switch viewSlots[indexPath.slotIndex] {
        case .favorite(let key):
            favorites.setVisibility(key: key, state: state)
        case .preset(let index):
            let soundFontAndPatch = SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: index)
            soundFonts.setVisibility(soundFontAndPatch: soundFontAndPatch, state: state)
        }
    }

    private func toggleVisibilityEditing(_ sender: AnyObject) {
        let button = sender as? UIButton
        button?.tintColor = view.isEditing ? .systemTeal : .systemOrange
        if view.isEditing == false {
            beginVisibilityEditing()
        }
        else {
            endVisibilityEditing()
        }
    }

    func performChanges(soundFont: LegacySoundFont) -> [IndexPath] {
        var changes = [IndexPath]()

        func processPresetConfig(_ slotIndex: Int, presetConfig: PresetConfig, slot: () -> Slot) {
            guard presetConfig.isVisible == false else { return }
            let indexPath = IndexPath(slotIndex: slotIndex)
            if view.isEditing {
                os_log(.info, log: log, "slot %d showing - '%{public}s'", slotIndex, presetConfig.name)
                viewSlots.insert(slot(), at: slotIndex)
                changes.append(indexPath)
                sectionRowCounts[indexPath.section] += 1
            }
            else {
                os_log(.info, log: log, "slot %d hiding - '%{public}s'", slotIndex, presetConfig.name)
                viewSlots.remove(at: slotIndex - changes.count)
                changes.append(indexPath)
                sectionRowCounts[indexPath.section] -= 1
            }
        }

        var slotIndex = 0
        for (presetIndex, preset) in soundFont.patches.enumerated() {
            processPresetConfig(slotIndex, presetConfig: preset.presetConfig) { .preset(index: presetIndex) }
            slotIndex += 1
            for favoriteKey in preset.favorites {
                let favorite = favorites.getBy(key: favoriteKey)
                processPresetConfig(slotIndex, presetConfig: favorite.presetConfig) { .favorite(key: favoriteKey) }
                slotIndex += 1
            }
        }

        return changes
    }

    private func beginVisibilityEditing() {
        withSoundFont { soundFont in
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.updateSectionRowCounts(reload: true)
                self.initializeVisibilitySelections(soundFont: soundFont)
                self.view.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
            view.setEditing(true, animated: true)

            let changes = performChanges(soundFont: soundFont)
            os_log(.info, log: log, "beginVisibilityEditing - %d changes", changes.count)

            view.performBatchUpdates({ view.insertRows(at: changes, with: .automatic) }, completion: nil)
            CATransaction.commit()
        }
    }

    private func endVisibilityEditing() {
        withSoundFont { soundFont in
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.updateSectionRowCounts(reload: true)
            }
            view.setEditing(false, animated: true)

            let changes = performChanges(soundFont: soundFont)
            os_log(.info, log: log, "endVisibilityEditing - %d changes", changes.count)

            view.performBatchUpdates {
                view.deleteRows(at: changes, with: .automatic)
            } completion: { _ in
                self.infoBar.hideMoreButtons()
            }

            CATransaction.commit()
        }
    }

    private func presetConfigForSlot(_ slot: Slot) -> PresetConfig? {
        return withSoundFont { soundFont in
            switch slot {
            case .favorite(let key): return favorites.getBy(key: key).presetConfig
            case .preset(let presetIndex): return soundFont.patches[presetIndex].presetConfig
            }
        }
    }

    private func initializeVisibilitySelections(soundFont: LegacySoundFont) {
        precondition(view.isEditing)
        os_log(.debug, log: self.log, "initializeVisibilitySelections")
        for (slotIndex, slot) in viewSlots.enumerated() {
            let indexPath = IndexPath(slotIndex: slotIndex)
            guard let presetConfig = presetConfigForSlot(slot) else { continue }
            if presetConfig.isVisible {
                view.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }

    private func activePatchChange(_ event: ActivePatchEvent) {
        switch event {
        case let .active(old: old, new: new, playSample: _):
            os_log(.debug, log: log, "activePatchChange")
            view.performBatchUpdates({
                updateView(with: old)
                updateView(with: new)
            }, completion: { finished in
                guard finished else { return }
                self.selectActive(animated: false)
            })
        }
    }

    private func selectedSoundFontChange(_ event: SelectedSoundFontEvent) {
        guard case let .changed(old: old, new: new) = event else { return }
        os_log(.info, log: log, "selectedSoundFontChange - old: '%{public}s' new: '%{public}s'",
               old?.displayName ?? "N/A", new?.displayName ?? "N/A")
        updateViewPresets()
        if view.isEditing {
            if let soundFont = new {
                initializeVisibilitySelections(soundFont: soundFont)
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

    private func favoritesRestored() {
        if let visibleRows = view.indexPathsForVisibleRows {
            view.reloadRows(at: visibleRows, with: .automatic)
        }
        else {
            view.reloadData()
        }
    }

    private func favoritesChange(_ event: FavoritesEvent) {
        os_log(.info, log: log, "favoritesChange")
        switch event {
        case .restored:
            os_log(.info, log: log, "favoritesChange - restored")
            favoritesRestored()

        case let .added(_, favorite):
            os_log(.info, log: log, "favoritesChange - added - %{public}s", favorite.key.uuidString)

        case let .removed(_, favorite):
            os_log(.info, log: log, "favoritesChange - removed - %{public}s", favorite.key.uuidString)

        case let .changed(_, favorite):
            os_log(.info, log: log, "favoritesChange - changed - %{public}s", favorite.key.uuidString)
            updateView(with: favorite)

        case .selected: break
        case .beginEdit: break
        case .removedAll: break
        }
    }

    private func soundFontsRestored() {
        updateViewPresets()
        selectActive(animated: false)
        hideSearchBar(animated: false)
    }

    private func soundFontsChange(_ event: SoundFontsEvent) {
        switch event {
        case let .unhidPresets(font: soundFont):
            if soundFont == selectedSoundFontManager.selected {
                updateViewPresets()
            }

        case let .presetChanged(soundFont, index):
            if soundFont == selectedSoundFontManager.selected {
                let soundFontAndPatch = soundFont.makeSoundFontAndPatch(at: index)
                updateView(with: soundFontAndPatch)
            }

        case .restored:
            if viewSlots.isEmpty {
                soundFontsRestored()
            }
        case .added: break
        case .moved: break
        case .removed: break
        }
    }

    private func getPresetIndexPath(for key: LegacyFavorite.Key) -> IndexPath? {
        guard favorites.contains(key: key) else { return nil }
        if showingSearchResults {
            guard let row = searchSlots.findFavoriteKey(key) else { return nil }
            return IndexPath(row: row, section: 0)
        }

        guard let index = viewSlots.findFavoriteKey(key) else { return nil }
        return IndexPath(slotIndex: index)
    }

    private func getPresetIndexPath(for soundFontAndPatch: SoundFontAndPatch?) -> IndexPath? {
        guard let soundFontAndPatch = soundFontAndPatch else { return nil }
        guard let soundFont = selectedSoundFontManager.selected,
              soundFont.key == soundFontAndPatch.soundFontKey else { return nil }
        let presetIndex = soundFontAndPatch.patchIndex
        if showingSearchResults {
            guard let row = searchSlots.findPresetIndex(presetIndex) else { return nil }
            return IndexPath(row: row, section: 0)
        }

        guard let index = viewSlots.findPresetIndex(presetIndex) else { return nil }
        return IndexPath(slotIndex: index)
    }

    private var showingSearchResults: Bool { searchBar.searchTerm != nil }

    private func dismissSearchResults() {
        os_log(.info, log: log, "dismissSearchResults")
        guard searchBar.text != nil else { return }
        searchBar.text = nil
        searchSlots.removeAll()
        view.reloadData()
        dismissSearchKeyboard()
    }

    private func search(for searchTerm: String) {
        os_log(.info, log: log, "search - '%{public}s'", searchTerm)
        lastSearchText = searchTerm
        withSoundFont { soundFont in
            searchSlots = viewSlots.filter { slot in
                let name: String = {
                    switch slot {
                    case .favorite(let key): return favorites.getBy(key: key).presetConfig.name
                    case .preset(let presetIndex): return soundFont.patches[presetIndex].presetConfig.name
                    }
                }()
                return name.localizedCaseInsensitiveContains(searchTerm)
            }
        }
        os_log(.info, log: log, "found %d matches", searchSlots.count)
        view.reloadData()
    }

    private func hideSearchBar(animated: Bool) {
        dismissSearchKeyboard()
        if showingSearchResults || view.contentOffset.y > searchBar.frame.size.height * 2 { return }
        os_log(.info, log: log, "hiding search bar")
        let view = self.view
        let contentOffset = CGPoint(x: 0, y: searchBar.frame.size.height)
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator( withDuration: 0.3, delay: 0.0, options: [.curveEaseOut],
                                                            animations: { view.contentOffset = contentOffset },
                                                            completion: { _ in view.contentOffset = contentOffset })
        }
        else {
            view.contentOffset = contentOffset
        }
    }

    func selectActive(animated: Bool) {
        os_log(.debug, log: log, "selectActive")
        guard let activeSlot: Slot = {
            switch activePatchManager.active {
            case let .preset(soundFontAndPatch): return .preset(index: soundFontAndPatch.patchIndex)
            case let .favorite(favorite): return .favorite(key: favorite.key)
            case .none: return nil
            }
        }() else { return }

        guard let slotIndex = (viewSlots.firstIndex { $0 == activeSlot }) else { return }
        let indexPath = IndexPath(slotIndex: slotIndex)
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
}

// MARK: - Swipe Actions

extension PatchesTableViewManager {

    private func leadingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        let slot = viewSlots[indexPath.slotIndex]
        let actions: [UIContextualAction] = {
            switch slot {
            case .preset:
                guard let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath) else { return [] }
                return [
                    editPresetSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch),
                    createFavoriteSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch)
                ]
            case .favorite:
                return [
                    editFavoriteSwipeAction(at: indexPath)
                ]
            }
        }()
        return makeSwipeActionConfiguration(actions: actions)
    }

    private func editPresetSwipeAction(at indexPath: IndexPath, cell: TableCell,
                                       soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Edit", color: .systemTeal) { _, view, completionHandler in
            var rect = self.view.rectForRow(at: indexPath)
            rect.size.width = 240.0
            self.favorites.beginEdit(
                config: FavoriteEditor.Config.preset(
                    state: FavoriteEditor.State(indexPath: indexPath, sourceView: view, sourceRect: view.bounds,
                                                currentLowestNote: self.keyboard?.lowestNote,
                                                completionHandler: completionHandler, soundFonts: self.soundFonts,
                                                soundFontAndPatch: soundFontAndPatch))
            )
        }
    }

    private func createFavoriteSwipeAction(at indexPath: IndexPath, cell: TableCell,
                                           soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "Fave", color: .systemOrange) { _, _, completionHandler in
            completionHandler(self.createFavorite(at: indexPath, with: soundFontAndPatch))
        }
    }

    private func createFavorite(at indexPath: IndexPath, with soundFontAndPatch: SoundFontAndPatch) -> Bool {
        guard let soundFont = self.soundFonts.getBy(key: soundFontAndPatch.soundFontKey) else { return false }
        let preset = soundFont.patches[soundFontAndPatch.patchIndex]
        guard let favorite = soundFonts.createFavorite(soundFontAndPatch: soundFontAndPatch,
                                                       keyboardLowestNote: keyboard?.lowestNote) else { return false }
        favorites.add(favorite: favorite)
        let favoriteIndex = IndexPath(slotIndex: indexPath.slotIndex + preset.favorites.count)

        view.performBatchUpdates {
            viewSlots.insert(.favorite(key: favorite.key), at: favoriteIndex.slotIndex)
            view.insertRows(at: [favoriteIndex], with: .automatic)
            sectionRowCounts[favoriteIndex.section] += 1
        } completion: { _ in
            self.updateSectionRowCounts(reload: true)
        }

        return true
    }

    private func deleteFavoriteSwipeAction(at indexPath: IndexPath, cell: TableCell) -> UIContextualAction {
        return UIContextualAction(tag: "Unfave", color: .systemRed) { _, _, completionHandler in
            completionHandler(self.deleteFavorite(at: indexPath, cell: cell))
        }
    }

    private func deleteFavorite(at indexPath: IndexPath, cell: TableCell) -> Bool {
        guard case let .favorite(key) = viewSlots[indexPath.slotIndex] else { fatalError("unexpected slot type") }
        let favorite = favorites.getBy(key: key)
        favorites.remove(key: key)
        soundFonts.deleteFavorite(soundFontAndPatch: favorite.soundFontAndPatch, key: favorite.key)
        view.performBatchUpdates {
            viewSlots.remove(at: indexPath.slotIndex)
            view.deleteRows(at: [indexPath], with: .automatic)
            sectionRowCounts[indexPath.section] -= 1
        } completion: { _ in
            self.updateSectionRowCounts(reload: true)
            if favorite == self.activePatchManager.favorite {
                self.activePatchManager.setActive(preset: favorite.soundFontAndPatch, playSample: false)
            }
        }

        return true
    }

    private func editFavoriteSwipeAction(at indexPath: IndexPath) -> UIContextualAction {
        return UIContextualAction(tag: "Edit", color: .systemOrange) { _, _, completionHandler in
            self.editFavorite(at: indexPath, completionHandler: completionHandler)
        }
    }

    private func editFavorite(at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) {
        guard case let .favorite(key) = viewSlots[indexPath] else { fatalError("unexpected nil") }
        let favorite = favorites.getBy(key: key)
        let position = favorites.index(of: favorite.key)
        var rect = view.rectForRow(at: indexPath)
        rect.size.width = 240.0
        let configState = FavoriteEditor.State(indexPath: IndexPath(item: position, section: 0),
                                               sourceView: view, sourceRect: view.bounds,
                                               currentLowestNote: self.keyboard?.lowestNote,
                                               completionHandler: completionHandler, soundFonts: self.soundFonts,
                                               soundFontAndPatch: favorite.soundFontAndPatch)
        let config = FavoriteEditor.Config.favorite(state: configState, favorite: favorite)
        self.favorites.beginEdit(config: config)
    }

    private func trailingSwipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell: TableCell = view.cellForRow(at: indexPath) else { return nil }
        guard let soundFontAndPatch = makeSoundFontAndPatch(at: indexPath) else { return nil }
        let slot = viewSlots[indexPath.slotIndex]
        let actions: [UIContextualAction] = {
            switch slot {
            case .preset:
                return [createHideSwipeAction(at: indexPath, cell: cell, soundFontAndPatch: soundFontAndPatch)]
            case .favorite:
                return [deleteFavoriteSwipeAction(at: indexPath, cell: cell)]
            }
        }()
        return makeSwipeActionConfiguration(actions: actions)
    }

    private func createHideSwipeAction(at indexPath: IndexPath, cell: TableCell,
                                       soundFontAndPatch: SoundFontAndPatch) -> UIContextualAction {
        return UIContextualAction(tag: "HideShield", color: .gray) { _, _, completionHandler in
            self.soundFonts.setVisibility(soundFontAndPatch: soundFontAndPatch, state: false)
            self.viewSlots.remove(at: indexPath.slotIndex)
            self.view.performBatchUpdates({
                self.view.deleteRows(at: [indexPath], with: .automatic)
                self.sectionRowCounts[indexPath.section] -= 1
            }, completion: { _ in
                self.updateSectionRowCounts(reload: true)
            })
            completionHandler(true)
        }
    }

    private func makeSwipeActionConfiguration(actions: [UIContextualAction]) -> UISwipeActionsConfiguration {
        let actions = UISwipeActionsConfiguration(actions: actions)
        actions.performsFirstActionWithFullSwipe = false
        return actions
    }
}

// MARK: - Updates

extension PatchesTableViewManager {

    private func getSlot(at indexPath: IndexPath) -> Slot {
        showingSearchResults ? searchSlots[indexPath] : viewSlots[indexPath]
    }

    private func makeSoundFontAndPatch(at indexPath: IndexPath) -> SoundFontAndPatch? {
        guard let soundFont = selectedSoundFontManager.selected else { return nil }
        let presetIndex: Int = {
            switch getSlot(at: indexPath) {
            case .favorite(let key): return favorites.getBy(key: key).soundFontAndPatch.patchIndex
            case .preset(let presetIndex): return presetIndex
            }
        }()
        return SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: presetIndex)
    }

    private func updateView(with activeKind: ActivePatchKind?) {
        os_log(.info, log: log, "updateView - with activeKind")
        guard let activeKind = activeKind else { return }
        switch activeKind {
        case .none: return
        case .preset(let soundFontAndPatch): updateView(with: soundFontAndPatch)
        case .favorite(let favorite): updateView(with: favorite)
        }
    }

    private func updateView(with favorite: LegacyFavorite) {
        os_log(.info, log: log, "updateView - with favorite")
        guard let indexPath = getPresetIndexPath(for: favorite.key),
              let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath)
    }

    private func updateView(with soundFontAndPatch: SoundFontAndPatch?) {
        os_log(.info, log: log, "updateView - with soundFontAndPatch")
        guard let indexPath = getPresetIndexPath(for: soundFontAndPatch),
              let cell: TableCell = view.cellForRow(at: indexPath) else { return }
        updateView(cell: cell, at: indexPath)
    }

    private func updateView(cell: TableCell, at indexPath: IndexPath) {
        guard let soundFont = selectedSoundFontManager.selected else {
            os_log(.error, log: log, "unexpected nil soundFont")
            return
        }

        switch viewSlots[indexPath.slotIndex] {
        case let .preset(presetIndex):
            let soundFontAndPatch = SoundFontAndPatch(soundFontKey: soundFont.key, patchIndex: presetIndex)
            let preset = soundFont.patches[presetIndex]
            os_log(.info, log: log, "updateView - preset '%{public}s' %d in row %d section %d",
                   preset.presetConfig.name, presetIndex, indexPath.row, indexPath.section)
            cell.updateForPreset(name: preset.presetConfig.name,
                                 isActive: soundFontAndPatch == activePatchManager.soundFontAndPatch &&
                                        activePatchManager.favorite == nil,
                                 isEditing: view.isEditing)
        case let .favorite(key):
            let favorite = favorites.getBy(key: key)
            os_log(.info, log: log, "updateView - favorite '%{public}s' in row %d section %d",
                   favorite.presetConfig.name, indexPath.row, indexPath.section)
            cell.updateForFavorite(name: favorite.presetConfig.name,
                                   isActive: activePatchManager.favorite == favorite)
        }
    }
}
