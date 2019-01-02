//
//  SoundFontPatchSearch.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/21/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 A manager of search results. The searching takes place when the user enters a search term in the UISearchBar; this
 class simply displays the results and routes certain user events to its delegate.
 */
final class SoundFontPatchSearchManager: NSObject {

    var delegate: SoundFontPatchSearchManagerDelegate? = nil

    private let resultsView: UITableView
    private var searchResults = [(index: Int, patch: Patch)]()
    private var activePatchIndex: Int = -1

    init(resultsView: UITableView) {
        self.resultsView = resultsView
    }

    /**
     Search the array of Patch instances for a given SoundFont and display the results in `resultsView`.
    
     - parameter soundFont: the SoundFont to query
     - parameter activePatchIndex: the index of the current active Patch or -1 if the SoundFont is not the active
       SoundFont
     - parameter term: the text to search for
     */
    func search(soundFont: SoundFont, activePatchIndex: Int, term: String) {
        self.activePatchIndex = activePatchIndex
        searchResults = zip(soundFont.patches.indices, soundFont.patches)
            .filter { $0.1.name.localizedCaseInsensitiveContains(term) }
        resultsView.reloadData()
        if searchResults.isEmpty {
            delegate?.scrollToSearchField()
        }
    }

    /**
     Scroll the search results so that the active Patch is visible.
     */
    func scrollToActivePatch() {
        let row = searchIndexOfPatch(patchIndex: activePatchIndex)
        if row != -1 {
            resultsView.scrollToRow(at: IndexPath(row: row, section: 0), at: .none, animated: true)
        }
        else {
            delegate?.scrollToSearchField()
        }
    }

    private func searchIndexOfPatch(patchIndex: Int) -> Int {
        return searchResults.firstIndex { $0.index == patchIndex } ?? -1
    }

    private func updateResultsCell(at index: Int, cell: SoundFontPatchCell? = nil) {
        guard let cell = cell ?? resultsView.cellForRow(at: IndexPath(row: index, section: 0)) as? SoundFontPatchCell
            else { return }
        let found = searchResults[index]
        let patch = found.patch
        delegate?.updateCell(cell, with: patch)
    }
}

// MARK: - UITableViewDataSource Protocol
extension SoundFontPatchSearchManager : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "search") as? SoundFontPatchCell else {
            preconditionFailure("expected to get a UITableViewCell")
        }

        updateResultsCell(at: indexPath.row, cell: cell)
        return cell
    }
}

// MARK: - UITableViewDelegate Protocol
extension SoundFontPatchSearchManager : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let prevIndex = activePatchIndex
        activePatchIndex = searchResults[indexPath.row].index
        delegate?.selected(patchIndex: activePatchIndex)
        updateResultsCell(at: searchIndexOfPatch(patchIndex: prevIndex))
        updateResultsCell(at: searchIndexOfPatch(patchIndex: activePatchIndex))
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Allow user to add/remove Favorite instance for a Patch from the search results
        guard let cell = tableView.cellForRow(at: indexPath) as? SoundFontPatchCell else { return nil }
        let patch = searchResults[indexPath.row].patch
        guard let action = delegate?.createSwipeAction(at: cell, with: patch) else { return nil }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle  {
        return UITableViewCell.EditingStyle.none
    }
}
