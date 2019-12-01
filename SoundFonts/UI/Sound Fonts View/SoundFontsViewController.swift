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
        patchesView.contentOffset = CGPoint(x: 0, y: searchBar.frame.size.height)
        restoreLastActivePatch()
    }

    private func restoreLastActivePatch() {
        let lastSoundFontUUID = UUID(uuidString: Settings[.lastActiveSoundFont]) ?? soundFontsTableViewDataSource.getBy(index: 0).uuid
        let soundFont = SoundFontLibrary.shared.getBy(uuid: lastSoundFontUUID)
        let patchIndex: Int = {
            let patchIndex = Settings[.lastActivePatch]
            return patchIndex >= 0 && patchIndex < soundFont.patches.count ? patchIndex : 0
        }()

        let patch = soundFont.patches[patchIndex]
        changeActivePatch(patch)
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
        let prevIndex = activePatchIndex
        activePatchIndex = index

        if updatePreviousCell && prevIndex != -1 && prevIndex != index {
            if let cell: PatchCell = patchesView.cellForRow(at: cellRow(at: prevIndex)) {
                let patch = activeSoundFont.patches[prevIndex]
                cell.setActive(false, isFavorite: favoritesManager.isFavored(patch: patch))
            }
        }

        let pos = cellRow(at: index)
        if let cell: PatchCell = patchesView.cellForRow(at: pos) {
            let patch = activeSoundFont.patches[index]
            cell.setActive(true, isFavorite: favoritesManager.isFavored(patch: patch))
        }
        
        if patchesView.indexPathForSelectedRow != pos {
            let scrollPosition: UITableView.ScrollPosition = pos.section == 0 && pos.row < 2 ? .top : .none
            self.patchesView.scrollToRow(at: pos, at: scrollPosition, animated: false)
            self.patchesView.selectRow(at: pos, animated: false, scrollPosition: scrollPosition)
        }
    }
    
    private func cellRow(at: Int) -> IndexPath {
        let row = searchBar.searchTerm != nil ? searchManager.searchIndexOfPatch(patchIndex: at) : at
        return patchesTableViewDataSource.indexPathForPatchIndex(row)
    }

    private func changeActivePatch(_ newPatch: Patch) {
        os_log(.info, log: logger, "changeActivePatch")
        guard newPatch != activePatch else { return }

        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
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
                                                                 collection: SoundFontLibrary.shared)

        patchesTableViewDataSource = PatchesTableViewDataSource(view: patchesView,
                                                                searchBar: searchBar,
                                                                activeSoundFontManager: self,
                                                                activePatchManager: self,
                                                                favoritesManager: context.favoritesManager,
                                                                keyboardManager: context.keyboardManager)

        favoritesManager = context.favoritesManager

        context.soundFontLibraryManager.addSoundFontLibraryChangeNotifier(self) { kind in
            switch kind {
            case .restored:
                self.soundFontsView.reloadData()
                // self.patchesView.reloadData()
                self.restoreLastActivePatch()
            default:
                self.soundFontsView.reloadData()
            }
        }
    }
}

// MARK: - ActiveSoundFontManager Protocol
extension SoundFontsViewController : ActiveSoundFontManager {

    var selectedIndex: Int {
        get {
            return self.selectedSoundFontIndex
        }

        set {
            guard newValue != selectedSoundFontIndex else { return }
            selectedSoundFontIndex = newValue
            
            let pos = IndexPath(row: newValue, section: 0)
            if soundFontsView.indexPathForSelectedRow != pos {
                soundFontsView.scrollToRow(at: pos, at: .none, animated: false)
                soundFontsView.selectRow(at: pos, animated: false, scrollPosition: .none)
            }

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

    var activePatch: Patch {
        get {
            self.activeSoundFont.patches[activePatchIndex]
        }
        set {
            changeActivePatch(newValue)
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
    func updateCell(_ cell: PatchCell, with patch: Patch) {
        patchesTableViewDataSource.updateCell(cell, with: patch)
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
            patchesView.dataSource = patchesTableViewDataSource
            patchesView.delegate = patchesTableViewDataSource
            patchesView.reloadData()
        }
    }
}
