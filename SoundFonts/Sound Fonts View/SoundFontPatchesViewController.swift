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
final class SoundFontPatchesViewController: UIViewController {

    @IBOutlet private weak var soundFontsView: UITableView!
    @IBOutlet private weak var patchesView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar!
    
    private var soundFontsTableViewDataSource: SoundFontsTableViewDataSource!
    private var patchesTableViewDataSource: PatchesTableViewDataSource!
    
    private var selectedSoundFontIndex: Int = 0
    private var selectedSoundFont: SoundFont { return SoundFont.getByIndex(selectedSoundFontIndex) }
    
    private var activeSoundFontIndex = 0
    private var activeSoundFont: SoundFont { return SoundFont.getByIndex(activeSoundFontIndex) }
    private var activePatchIndex = 0
    
    private var searchManager: SoundFontPatchSearchManager!
    private var notifiers = [(Patch)->Void]()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        searchManager = SoundFontPatchSearchManager(resultsView: patchesView)
        searchManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        restoreActivePatch()

        soundFontsTableViewDataSource.selectRow(at: activeSoundFontIndex, animated: false)
        patchesTableViewDataSource.scrollToRow(at: 0, at: .top, animated: false)
        patchesTableViewDataSource.selectRow(at: activePatchIndex, animated: false)
    }
    
    private func restoreActivePatch() {
        let lastSoundFontName = Settings[.activeSoundFont]
        let lastSoundFontIndex = SoundFont.indexForName(lastSoundFontName)
        if lastSoundFontIndex == -1 {
            return
        }

        self.selectedIndex = lastSoundFontIndex

        let lastPatchIndex = max(min(Settings[.activePatch], selectedSoundFont.patches.count - 1), 0)
        changeActivePatchIndex(lastPatchIndex)
    }
    
    private func setActiveSoundFontIndex() {
        let prevIndex = activeSoundFontIndex
        if prevIndex != selectedSoundFontIndex {
            activeSoundFontIndex = selectedSoundFontIndex
            soundFontsTableViewDataSource.refreshRow(at: prevIndex)
            soundFontsTableViewDataSource.refreshRow(at: selectedSoundFontIndex)
        }
    }
    
    private func setActivePatchIndex(_ index: Int) -> Bool {
        let prevIndex = activePatchIndex
        if prevIndex != index {
            activePatchIndex = index
            patchesTableViewDataSource.refreshRow(at: prevIndex)
            patchesTableViewDataSource.refreshRow(at: activePatchIndex)
            return true
        }
        return false
    }
    
    private func changeActivePatchIndex(_ index: Int) {
        if searchBar.isFirstResponder && searchBar.canResignFirstResponder {
            searchBar.resignFirstResponder()
        }

        setActiveSoundFontIndex()
        if setActivePatchIndex(index) {
            notifiers.forEach { $0(activePatch) }
        }
    }
}

// MARK: - ControllerConfiguration
extension SoundFontPatchesViewController: ControllerConfiguration {
    func establishConnections(_ context: RunContext) {
        soundFontsTableViewDataSource = SoundFontsTableViewDataSource(view: soundFontsView,
                                                                      searchBar: searchBar,
                                                                      activeSoundFontManager: self)
        soundFontsView.dataSource = soundFontsTableViewDataSource
        soundFontsView.delegate = soundFontsTableViewDataSource
        
        patchesTableViewDataSource = PatchesTableViewDataSource(view: patchesView,
                                                                searchBar: searchBar,
                                                                activeSoundFontManager: self,
                                                                activePatchManager: self,
                                                                favoritesManager: context.favoritesManager,
                                                                keyboardManager: context.keyboardManager)
        patchesView.dataSource = patchesTableViewDataSource
        patchesView.delegate = patchesTableViewDataSource
    }
}

// MARK: - ActiveSoundFontManager Protocol
extension SoundFontPatchesViewController : ActiveSoundFontManager {
    var activeIndex: Int {
        get {
            return self.activeSoundFontIndex
        }
        set {
            self.selectedSoundFontIndex = newValue
            setActiveSoundFontIndex()
        }
    }
    
    var selectedIndex: Int {
        get {
            return self.selectedSoundFontIndex
        }
        set {
            self.selectedSoundFontIndex = newValue
            let selectedSoundFont = SoundFont.getByIndex(newValue)
            if let searchTerm = searchBar.searchTerm {
                let activePatchIndex = activeSoundFontIndex == selectedSoundFontIndex ? self.activePatchIndex : -1
                searchManager.search(soundFont: selectedSoundFont, activePatchIndex: activePatchIndex, term: searchTerm)
            }
            else {
                patchesView.reloadData()
            }
        }
    }
}

// MARK: - ActivePatchManager Protocol
extension SoundFontPatchesViewController: ActivePatchManager {
    var patches: [Patch] { return self.selectedSoundFont.patches }
    var activePatch: Patch {
        get {
            return self.activeSoundFont.patches[activePatchIndex]
        }
        set {
            changeActivePatchIndex(newValue.index)
        }
    }

    func addPatchChangeNotifier(_ notifier: @escaping (Patch) -> Void) {
        notifiers.append(notifier)
    }
}

// MARK: - SoundFontPatchSearchManagerDelegate Protocol
extension SoundFontPatchesViewController : SoundFontPatchSearchManagerDelegate {
    func selected(patchIndex: Int) {
        changeActivePatchIndex(patchIndex)
    }

    func scrollToSearchField() {
        patchesView.scrollRectToVisible(searchBar.frame, animated: true)
    }
    
    func updateCell(_ cell: SoundFontPatchCell, with patch: Patch) {
        patchesTableViewDataSource.updateCell(cell, with: patch)
    }

    func createSwipeAction(at cell: SoundFontPatchCell, with patch: Patch) -> UIContextualAction {
        return patchesTableViewDataSource.createSwipeAction(at: cell, with: patch)
    }
}

// MARK: - UISearchBarDelegate Protocol
extension SoundFontPatchesViewController : UISearchBarDelegate {
    
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
