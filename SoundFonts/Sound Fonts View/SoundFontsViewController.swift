//  Copyright © 2018 Brad Howes. All rights reserved.

import UIKit

extension SettingKeys {
    static let activeSoundFont = SettingKey<String>("activeSoundFont", defaultValue: SoundFont.keys[0])
    static let activePatch = SettingKey<Int>("activePatch", defaultValue: 0)
}

/**
 View controller for the SoundFont / Patches UITableView combination. Much of the UITableView managemnet is handled
 by specific *DataSource classes. This controller mainly serves to manage the active Patch state, plus the switching
 between normal Pathc table view display and Patch search results display. Apart from the adopted protocols, there is no
 public API for this class.
 */
final class SoundFontsViewController: UIViewController {

    @IBOutlet private weak var soundFontsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!
    
    private var soundFontsTableViewDataSource: FontsTableViewDataSource!
    private var patchesTableViewDataSource: PatchesTableViewDataSource!
    
    private var selectedSoundFontIndex: Int = -1
    private var selectedSoundFont: SoundFont { return SoundFont.getByIndex(selectedSoundFontIndex) }
    private var activeSoundFontIndex = -1
    private var activeSoundFont: SoundFont { return SoundFont.getByIndex(activeSoundFontIndex) }

    private var activePatchIndex = -1

    private var searchManager: PatchSearchManager!
    private var notifiers = [UUID: (Patch) -> Void]()

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

    func restoreLastActivePatch() {
        let lastSoundFontName = Settings[.activeSoundFont]
        guard let soundFont = SoundFont.library[lastSoundFontName] else {
            selectedIndex = 0
            activeIndex = 0
            setActivePatchIndex(0, previousExists: false)
            return
        }

        let patchIndex: Int = {
            let patchIndex = Settings[.activePatch]
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
                cell.setActive(false)
            }

            if let cell: FontCell = soundFontsView.cellForRow(at: IndexPath(row: index, section: 0)) {
                cell.setActive(true)
            }
        }

        selectedIndex = index
        return prevIndex != index
    }

    private func setActivePatchIndex(_ index: Int, previousExists: Bool) {
        let prevIndex = activePatchIndex
        activePatchIndex = index

        if previousExists && prevIndex != -1 && prevIndex != index {
            if let cell: PatchCell = patchesView.cellForRow(at: cellRow(at: prevIndex)) {
                cell.setActive(false)
            }
        }

        let pos = cellRow(at: index)
        if let cell: PatchCell = patchesView.cellForRow(at: pos) {
            cell.setActive(true)
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

    private func changeActivePatch(_ patch: Patch?) {
        guard let patch = patch else { return }
        guard patch != activePatch else { return }

        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }

        let fontChanged = setActiveSoundFontIndex(SoundFont.indexForName(patch.soundFont.name))
        setActivePatchIndex(patch.index, previousExists: !fontChanged)
        
        notifiers.values.forEach { $0(patch) }
    }
}

// MARK: - ControllerConfiguration
extension SoundFontsViewController: ControllerConfiguration {
    func establishConnections(_ context: RunContext) {
        soundFontsTableViewDataSource = FontsTableViewDataSource(view: soundFontsView,
                                                                      searchBar: searchBar,
                                                                      activeSoundFontManager: self)
        
        patchesTableViewDataSource = PatchesTableViewDataSource(view: patchesView,
                                                                searchBar: searchBar,
                                                                activeSoundFontManager: self,
                                                                activePatchManager: self,
                                                                favoritesManager: context.favoritesManager,
                                                                keyboardManager: context.keyboardManager)
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
                let selectedSoundFont = SoundFont.getByIndex(selectedSoundFontIndex)
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
}

// MARK: - ActivePatchManager Protocol
extension SoundFontsViewController: ActivePatchManager {

    var patches: [Patch] { return self.selectedSoundFont.patches }

    var activePatch: Patch? {
        get {
            return activePatchIndex == -1 ? nil : self.activeSoundFont.patches[activePatchIndex]
        }
        set {
            changeActivePatch(newValue)
        }
    }

    func addPatchChangeNotifier<O: AnyObject>(_ observer: O, closure: @escaping Notifier<O>) -> NotifierToken {
        let uuid = UUID()

        // For the cancellation closure, we do not want to create a hold cycle, so capture a weak self
        let token = NotifierToken { [weak self] in self?.notifiers.removeValue(forKey: uuid) }
        
        // For this closure, we don't need a weak self since we are holding the collection and they cannot run outside
        // of the main thread. However, we don't want to keep the observer from going away, so treat that as weak and
        // protect against it being nil.
        notifiers[uuid] = { [weak observer] patch in
            if let strongObserver = observer {
                closure(strongObserver, patch)
            }
            else {
                token.cancel()
            }
        }

        // For the cancellation closure, we do not want to create a hold cycle, so capture a weak self and protect
        // against it being nil.
        return NotifierToken { [weak self] in self?.notifiers.removeValue(forKey: uuid) }
    }

    func removeNotifier(forKey key: UUID) {
        notifiers.removeValue(forKey: key)
    }
}

extension SoundFontsViewController: PatchesManager {
    func addTarget(_ event: SwipingEvent, target: Any, action: Selector) {
        switch event {
        case .swipeLeft: swipeLeft.addTarget(target, action: action)
        case .swipeRight: swipeRight.addTarget(target, action: action)
        }
    }
}

// MARK: - PatchSearchManagerDelegate Protocol
extension SoundFontsViewController: PatchSearchManagerDelegate {
    func selected(patch: Patch) {
        changeActivePatch(patch)
    }

    func scrollToSearchField() {
        patchesView.scrollRectToVisible(searchBar.frame, animated: true)
    }
    
    func updateCell(_ cell: PatchCell, with patch: Patch) {
        patchesTableViewDataSource.updateCell(cell, with: patch)
    }

    func createSwipeAction(at cell: PatchCell, with patch: Patch) -> UIContextualAction {
        return patchesTableViewDataSource.createSwipeAction(at: cell, with: patch)
    }
}

// MARK: - UISearchBarDelegate Protocol
extension SoundFontsViewController : UISearchBarDelegate {
    
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
