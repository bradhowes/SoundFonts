//
//  SoundFontPicker.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/20/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

extension SettingKeys {
    static let activeSoundFont = SettingKey<String>("activeSoundFont", defaultValue: "Fluid R3 GM")
    static let activePatch = SettingKey<Int>("activePatch", defaultValue: 13)
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
    
    private var selectedSoundFontIndex: Int = 0 {
        didSet {
            let selectedSoundFont = SoundFont.getByIndex(selectedSoundFontIndex)
            if let searchTerm = searchBar.searchTerm {
                let activePatchIndex = activeSoundFontIndex == selectedSoundFontIndex ? self.activePatchIndex : -1
                searchManager.search(soundFont: selectedSoundFont, activePatchIndex: activePatchIndex, term: searchTerm)
            }
            else {
                patchesView.reloadData()
            }
        }
    }

    private var selectedSoundFont: SoundFont { return SoundFont.getByIndex(selectedSoundFontIndex) }

    private var activeSoundFontIndex = -1
    private var activeSoundFont: SoundFont { return SoundFont.getByIndex(activeSoundFontIndex) }

    private var activePatchIndex = -1

    private var searchManager: PatchSearchManager!
    private var notifiers = [UUID: (Patch) -> Void]()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        searchManager = PatchSearchManager(resultsView: patchesView)
        searchManager.delegate = self
    }

    func restoreLastActivePatch() {
        let lastSoundFontName = Settings[.activeSoundFont]
        guard let soundFont = SoundFont.library[lastSoundFontName] else { return }
        let patchIndex = max(min(Settings[.activePatch], soundFont.patches.count - 1), 0)
        let patch = soundFont.patches[patchIndex]
        activeSoundFontIndex = -1
        activePatchIndex = -1
        changeActivePatch(patch)
    }

    private func setActiveSoundFontIndex(_ index: Int) {
        let prevIndex = activeSoundFontIndex
        if prevIndex != index {
            activeSoundFontIndex = index
            soundFontsTableViewDataSource.refreshRow(at: prevIndex)
            soundFontsTableViewDataSource.refreshRow(at: index)
        }

        selectedSoundFontIndex = index
        soundFontsTableViewDataSource.selectRow(at: index, animated: false)
    }

    private func setActivePatchIndex(_ index: Int) {
        let prevIndex = activePatchIndex
        activePatchIndex = index
        if prevIndex != -1 && prevIndex != activePatchIndex {
            patchesTableViewDataSource.refreshRow(at: prevIndex)
        }

        patchesTableViewDataSource.refreshRow(at: index)
        
        // If we are not searching, scroll to the current row. However, we need to do this in the future because
        // right now we could be awaiting a reload due to a SoundFont change.
        if searchBar.searchTerm == nil {
            DispatchQueue.main.async {
                self.patchesTableViewDataSource.scrollToRow(at: self.activePatchIndex, at: .none, animated: false)
                self.patchesTableViewDataSource.selectRow(at: self.activePatchIndex, animated: false,
                                                          scrollPosition: .none)
            }
        }
    }
    
    private func changeActivePatch(_ patch: Patch?) {
        guard let patch = patch else { return }
        guard patch != activePatch else { return }

        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }

        setActiveSoundFontIndex(SoundFont.indexForName(patch.soundFont.name))
        setActivePatchIndex(patch.index)
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
            self.selectedSoundFontIndex = newValue
        }
    }

    var activeIndex: Int {
        get {
            return self.activeSoundFontIndex
        }
        set {
            setActiveSoundFontIndex(newValue)
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

// MARK: - SoundFontPatchSearchManagerDelegate Protocol
extension SoundFontsViewController : SoundFontPatchSearchManagerDelegate {
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
