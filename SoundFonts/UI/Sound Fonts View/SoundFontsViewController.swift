// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

extension SettingKeys {
    static let lastActiveSoundFont = SettingKey<String>("activeSoundFont", defaultValue: "")
    static let lastActivePatch = SettingKey<Int>("activePatch", defaultValue: 0)
}

/**
 View controller for the SoundFont / Patches UITableView combination. Much of the UITableView management is handled
 by specific *DataSource classes. This controller mainly serves to manage the active Patch state, plus the switching
 between normal Patch table view display and Patch search results display. Apart from the adopted protocols, there is no
 public API for this class.

 Perhaps this should be split into two, one for a soundfont view, and one for the patches view.
 */
final class SoundFontsViewController: UIViewController {
    private lazy var logger = Logging.logger("SFVC")

    @IBOutlet private weak var soundFontsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!
    
    private var soundFontsTableViewDataSource: FontsTableViewDataSource!
    private var patchesTableViewDataSource: PatchesTableViewDataSource!
    
    private var selectedSoundFontIndex: Int = 0
    private var activeSoundFontIndex: Int = 0
    private var activePatchIndex: Int = 0

    private var favoritesManager: FavoritesManager!
    private var searchManager: PatchSearchManager!
    private var notifiers = [UUID: (Patch, Patch) -> Void]()

    private var swipeLeft = UISwipeGestureRecognizer()
    private var swipeRight = UISwipeGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()

        swipeLeft.direction = .left
        swipeLeft.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeLeft)

        swipeRight.direction = .right
        swipeRight.numberOfTouchesRequired = 2
        view.addGestureRecognizer(swipeRight)

        searchBar.delegate = self
        searchManager = PatchSearchManager(resultsView: patchesView)
        searchManager.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        if patchesView.indexPathForSelectedRow == nil {
            restoreLastActivePatch()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
            let vc = nc.topViewController as? FontDetailController,
            let cell = sender as? FontCell,
            let indexPath = soundFontsView.indexPath(for: cell) else { return }

        vc.delegate = self

        let soundFont = soundFontsTableViewDataSource.getBy(index: indexPath.row)
        vc.edit(soundFont: soundFont, favoriteCount: favoritesManager.count(associatedWith: soundFont),
                position: indexPath)

        // Now if showing a popover, position it in the right spot
        //
        if let ppc = nc.popoverPresentationController {

            ppc.barButtonItem = nil // !!! Muy importante !!!
            ppc.sourceView = cell

            // Focus on the indicator -- this may not be correct for all locales.
            let rect = cell.bounds
            ppc.sourceRect = view.convert(CGRect(origin: rect.offsetBy(dx: rect.width - 32, dy: 0).origin,
                                                 size: CGSize(width: 32.0, height: rect.height)), to: nil)
        }
    }

    private func restoreLastActivePatch() {
        os_log(.info, log: logger, "restoreLastActivePatch")
        let lastSoundFont: SoundFont = {
            let uuidString = Settings[.lastActiveSoundFont]
            guard let lastSoundFontUUID = UUID(uuidString: uuidString) else {
                os_log(.error, log: logger, "invalid soundFont UUID - %s", uuidString)
                return nil
            }

            guard let soundFont = SoundFontLibrary.shared.getBy(uuid: lastSoundFontUUID) else {
                os_log(.error, log: logger, "unknown soundFont - %s", uuidString)
                return nil
            }

            return soundFont
        }() ?? soundFontsTableViewDataSource.getBy(index: 0)

        let patchIndex: Int = {
            let patchIndex = Settings[.lastActivePatch]
            guard patchIndex >= 0 && patchIndex < lastSoundFont.patches.count else {
                os_log(.error, log: logger, "invalid patchIndex - %d", patchIndex)
                return 0
            }
            return patchIndex
        }()

        let patch = lastSoundFont.patches[patchIndex]

        changeActivePatch(patch)

        let soundFontPos = IndexPath(row: activeSoundFontIndex, section: 0)
        let patchPos = cellRow(at: activePatchIndex)

        DispatchQueue.main.async {
            self.soundFontsView.selectRow(at: soundFontPos, animated: false, scrollPosition: .none)
            self.patchesView.selectRow(at: patchPos, animated: false, scrollPosition: .none)
        }
    }

    private func setActiveSoundFontIndex(_ index: Int) -> Bool {
        let prevIndex = activeSoundFontIndex
        if prevIndex != index {
            activeSoundFontIndex = index
            if let cell: FontCell = soundFontsView.cellForRow(at: IndexPath(row: prevIndex, section: 0)) {
                cell.setActive(false, isFavorite: false)
            }

            if let cell: FontCell = soundFontsView.cellForRow(at: IndexPath(row: index, section: 0)) {
                cell.setActive(true, isFavorite: false)
            }
        }

        selectedIndex = index
        return prevIndex != index
    }

    private func setActivePatchIndex(_ index: Int, updatePreviousCell: Bool) {
        os_log(.info, log: logger, "setActivePatchIndex - index: %d updatePreviousCell: %d", index, updatePreviousCell)

        let prevIndex = activePatchIndex
        activePatchIndex = index

        if updatePreviousCell && prevIndex != -1 && prevIndex != index && prevIndex < activeSoundFont.patches.count {
            if let cell: PatchCell = patchesView.cellForRow(at: cellRow(at: prevIndex)) {
                os_log(.info, log: logger, "updating old cell")
                let patch = activeSoundFont.patches[prevIndex]
                cell.setActive(false, isFavorite: favoritesManager.isFavored(patch: patch))
            }
        }

        let pos = cellRow(at: index)
        os_log(.info, log: logger, "pos: (%d, %d)", pos.section, pos.row)

        if let cell: PatchCell = patchesView.cellForRow(at: pos) {
            os_log(.info, log: logger, "updating new cell")
            let patch = activeSoundFont.patches[index]
            cell.setActive(true, isFavorite: favoritesManager.isFavored(patch: patch))
        }
        
        if patchesView.indexPathForSelectedRow != pos {
            os_log(.info, log: logger, "selecting new cell")
            patchesView.selectRow(at: pos, animated: false, scrollPosition: .none)
        }

        os_log(.info, log: logger, "scrolling to new cell")
        patchesView.scrollToRow(at: pos, at: .none, animated: false)

        hideSearchBar()
    }

    private func hideSearchBar() {
        if !showingSearchResults && patchesView.contentOffset.y < searchBar.frame.size.height {
            os_log(.info, log: logger, "hiding search bar")
            let offset = CGPoint(x: 0, y: searchBar.frame.size.height)
            UIView.animate(withDuration: 0.4) {
                self.patchesView.contentOffset = offset
            }
        }
    }

    private func cellRow(at: Int) -> IndexPath {
        let row = showingSearchResults ? searchManager.searchIndexOfPatch(patchIndex: at) : at
        return patchesTableViewDataSource.indexPathForPatchIndex(row)
    }

    private func changeActivePatch(_ newPatch: Patch) {
        os_log(.info, log: logger, "changeActivePatch - patch: '%s'", newPatch.description)
        // guard newPatch != activePatch else { return }

        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            os_log(.info, log: logger, "resigning first responder (keyboard)")
            searchBar.resignFirstResponder()
        }

        let oldPatch = activePatch
        let newSoundFont = newPatch.soundFont

        let fontChanged = setActiveSoundFontIndex(soundFontsTableViewDataSource.index(of: newSoundFont.uuid))
        setActivePatchIndex(newPatch.index, updatePreviousCell: !fontChanged)
        notifiers.values.forEach { $0(oldPatch, newPatch) }
    }
}

// MARK: - ControllerConfiguration
extension SoundFontsViewController: ControllerConfiguration {

    func establishConnections(_ context: RunContext) {
        soundFontsTableViewDataSource = FontsTableViewDataSource(view: soundFontsView,
                                                                 searchBar: searchBar,
                                                                 activeSoundFontManager: self,
                                                                 soundFontEditor: self,
                                                                 collection: SoundFontLibrary.shared)
        patchesTableViewDataSource = PatchesTableViewDataSource(view: patchesView,
                                                                searchBar: searchBar,
                                                                activeSoundFontManager: self,
                                                                activePatchManager: self,
                                                                favoritesManager: context.favoritesManager,
                                                                keyboardManager: context.keyboardManager)
        favoritesManager = context.favoritesManager
        context.soundFontLibraryManager.addSoundFontLibraryChangeNotifier(self) { kind in
            self.soundFontsView.reloadData()
            if case .restored = kind {
                self.restoreLastActivePatch()
            }
        }
    }
}

// MARK: - ActiveSoundFontManager Protocol
extension SoundFontsViewController: ActiveSoundFontManager {

    var selectedIndex: Int {
        get {
            return self.selectedSoundFontIndex
        }

        set {
            os_log(.info, log: logger, "set selectedIndex - current: %d new: %d", selectedSoundFontIndex, newValue)
            selectedSoundFontIndex = newValue
            
            let pos = IndexPath(row: newValue, section: 0)
            if soundFontsView.indexPathForSelectedRow != pos {
                soundFontsView.selectRow(at: pos, animated: false, scrollPosition: .none)
            }
            soundFontsView.scrollToRow(at: pos, at: .none, animated: false)

            if let searchTerm = searchBar.searchTerm {
                let api = activeSoundFontIndex == selectedSoundFontIndex ? activePatchIndex : -1
                let selectedSoundFont = soundFontsTableViewDataSource.getBy(index: selectedSoundFontIndex)
                searchManager.search(soundFont: selectedSoundFont, activePatchIndex: api, term: searchTerm)
            }
            else {
                patchesView.reloadData()
            }
        }
    }

    var activeIndex: Int {
        get {
            return self.activeSoundFontIndex
        }
        set {
            guard newValue != activeSoundFontIndex else { return }
            selectedIndex = newValue
            _ = setActiveSoundFontIndex(newValue)
        }
    }

    var selectedSoundFont: SoundFont { soundFontsTableViewDataSource.getBy(index: selectedIndex) }

    var activeSoundFont: SoundFont { soundFontsTableViewDataSource.getBy(index: activeIndex) }
}

// MARK: - ActivePatchManager Protocol
extension SoundFontsViewController: ActivePatchManager {

    var activePatch: Patch { self.activeSoundFont.patches[activePatchIndex] }

    func changePatch(kind: PatchKind) {
        os_log(.info, log: logger, "changePatch - kind: '%s'", kind.description)
        switch kind {
        case let .normal(patch: patch):

            // User picked a patch from the patch view.
            changeActivePatch(patch)

        case let .favorite(favorite: favorite):

            // User picked a favorite.
            if showingSearchResults {
                os_log(.info, log: logger, "showing search results")
                dismissSearchResults()
            }
            changeActivePatch(favorite.patch)
            hideSearchBar()
        }
    }

    /**
     Add an observer for patch changes.

     - parameter observer: the object that is interested in the patch change notifications.
     - parameter closure: the closure to invoke when the patch changes.
     */
    func addPatchChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken {
        let uuid = UUID()
        let token = NotifierToken { [weak self] in self?.notifiers.removeValue(forKey: uuid) }
        notifiers[uuid] = { [weak observer] old, new in
            os_log(.info, log: self.logger, "patch changed notification")
            if observer != nil {
                closure(old, new)
            }
            else {
                token.cancel()
            }
            os_log(.info, log: self.logger, "done")
        }

        return token
    }

    /**
     Remove a registered observer.

     - parameter forKey: the unique identifier for the observer to remove.
     */
    func removeNotifier(forKey key: UUID) {
        notifiers.removeValue(forKey: key)
    }
}

extension SoundFontsViewController: PatchesManager {

    /**
     Attach an event notification to the given object/selector pair so that future events will invoke the selector.

     - parameter event: the event to attach to
     - parameter target: the object to notify
     - parameter action: the selector to invoke
     */
    func addTarget(_ event: SwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }

    func dismissSearchKeyboard() {
        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }
    }
}

extension SoundFontsViewController: SoundFontEditor {

    func createEditSwipeAction(at cell: FontCell, with soundFont: SoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) {
            (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            self.performSegue(withIdentifier: "soundFontDetail", sender: cell)
            completionHandler(true)
        }

        action.image = UIImage(named: "Edit")
        action.backgroundColor = UIColor.orange
        return action
    }

    func createDeleteSwipeAction(at cell: FontCell, with soundFont: SoundFont) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { (_, _, completionHandler) in
            let alertController = UIAlertController(title: "Confirm", message: "Deleting the SoundFont cannot be undone.",
                                                    preferredStyle: .actionSheet)
            let delete = UIAlertAction(title: "Delete", style:.destructive) { action in
                SoundFontLibrary.shared.remove(soundFont: soundFont)
                completionHandler(true)
            }

            let cancel = UIAlertAction(title: "Cancel", style:.cancel) { action in
                completionHandler(false)
            }

            alertController.addAction(delete)
            alertController.addAction(cancel)

            if let popoverController = alertController.popoverPresentationController {
              popoverController.sourceView = self.view
              popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
              popoverController.permittedArrowDirections = []
            }

            self.present(alertController, animated: true, completion: nil)
        }

        action.image = UIImage(named: "Trash")
        action.backgroundColor = UIColor.red
        return action
    }
}

// MARK: - PatchSearchManagerDelegate Protocol
extension SoundFontsViewController: PatchSearchManagerDelegate {

    /**
     Notification that a patch in the search result was selected.

     - parameter patch: the patch to make active
     */
    func selected(patch: Patch) {
        changeActivePatch(patch)
    }

    /**
     Show the patch search field.
     */
    func scrollToSearchField() {
        patchesView.scrollRectToVisible(searchBar.frame, animated: true)
    }

    /**
     Update the tableview cell with the search information.

     - parameter cell: the cell to update
     - parameter with: the patch to represent in the cell
     */
    func update(cell: PatchCell, with patch: Patch) {
        patchesTableViewDataSource.update(cell: cell, with: patch)
    }

    /**
     Attach swipe actions to a cell

     - parameter at: the cell to attach to
     - parameter with: the patch represented in the cell
     - returns swipe action for the cell
     */
    func createSwipeAction(at cell: PatchCell, with patch: Patch) -> UIContextualAction {
        return patchesTableViewDataSource.createSwipeAction(at: cell, with: patch)
    }
}

// MARK: - UISearchBarDelegate Protocol
extension SoundFontsViewController : UISearchBarDelegate {

    /**
     Notification that the content of the search field changed. Update the search results based on the new contents. If
     the search field is empty, replace the search results with the patch listing.

     - parameter searchBar: the UISearchBar where the event took place
     - parameter textDidChange: the current contents of the text field
     */
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchTerm = searchBar.searchTerm {
            patchesView.dataSource = searchManager
            patchesView.delegate = searchManager
            searchManager.search(soundFont: selectedSoundFont,
                                 activePatchIndex: activeSoundFontIndex == selectedSoundFontIndex ? activePatchIndex : -1,
                                 term: searchTerm)
        }
        else {
            dismissSearchResults()
        }
    }

    var showingSearchResults: Bool { searchBar.searchTerm != nil }

    func dismissSearchResults() {
        os_log(.info, log: logger, "dismissSearchResults")
        searchBar.text = nil
        patchesView.dataSource = patchesTableViewDataSource
        patchesView.delegate = patchesTableViewDataSource
        patchesView.reloadData()
    }
}

// MARK: - SoundFontDetailControllerDelegate

extension SoundFontsViewController: SoundFontDetailControllerDelegate {
    func dismissed(reason: SoundFontDetailControllerDismissedReason) {
        switch reason {
        case let .done(indexPath: _, soundFont: soundFont):

            // Get the UUID of the selected and active SoundFont entries *before* the change in name.
            let selectedUUID = selectedSoundFont.uuid
            let activeUUID = activeSoundFont.uuid

            SoundFontLibrary.shared.renamed(soundFont: soundFont)

            // Update the selected/active SoundFont values to reflect any changes due to reordering
            let newActiveSoundFontIndex = soundFontsTableViewDataSource.index(of: activeUUID)
            if activeSoundFontIndex != newActiveSoundFontIndex {
                activeSoundFontIndex = newActiveSoundFontIndex
            }

            let newSelectedSoundFontIndex = soundFontsTableViewDataSource.index(of: selectedUUID)
            if selectedSoundFontIndex != newSelectedSoundFontIndex {
                selectedSoundFontIndex = newSelectedSoundFontIndex
            }

        case .cancel:
            break

        case let .delete(indexPath: _, soundFont: soundFont):
            print("delete \(soundFont.displayName)")
            break
        }

        self.dismiss(animated: true, completion: nil)
    }
}


