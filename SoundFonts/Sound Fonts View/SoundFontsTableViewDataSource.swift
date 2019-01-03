//
//  SoundFontsTableDataSource.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/27/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Data source for the SoundFont UITableView.
 */
final class SoundFontsTableViewDataSource: NSObject {

    let view: UITableView
    let searchBar: UISearchBar
    let activeSoundFontManager: ActiveSoundFontManager

    init(view: UITableView, searchBar: UISearchBar, activeSoundFontManager: ActiveSoundFontManager) {
        self.view = view
        self.searchBar = searchBar
        self.activeSoundFontManager = activeSoundFontManager
    }

    /**
     Update the view so that the entry at the given index is visible.
     
     - parameter index: Patch index to make visible
     - parameter position: where in the view to place the row
     - parameter animated: if true animate the scrolling
     */
    func scrollToRow(at index: Int, at position: UITableView.ScrollPosition, animated: Bool) {
        view.scrollToRow(at: IndexPath(row: index, section: 0), at: position, animated: animated)
    }

    /**
     Select a row in the table view.
    
     - parameter index: the row to select
     - parameter animated: true if selection should be animated
     */
    func selectRow(at index: Int, animated: Bool) {
        view.selectRow(at: IndexPath(row: index, section: 0), animated: animated, scrollPosition: .none)
    }

    /**
     Update a row in the table view.
    
     - parameter index: the index to update
     */
    func refreshRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        guard let cell = view.cellForRow(at: indexPath) as? SoundFontPatchCell else { return }
        updateCell(at: indexPath, cell: cell)
    }

    private func updateCell(at indexPath: IndexPath, cell: SoundFontPatchCell) {
        cell.update(name: SoundFont.keys[indexPath.row],
                    isActive: indexPath.row == activeSoundFontManager.activeIndex)
    }
}

// MARK: - UITableViewDataSource Protocol
extension SoundFontsTableViewDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SoundFont.keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "soundFont") as? SoundFontPatchCell else {
            preconditionFailure("expected to get a UITableViewCell")
        }
        updateCell(at: indexPath, cell: cell)
        return cell
    }
}

// MARK: - UITableViewDelegate Protocol
extension SoundFontsTableViewDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle  {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activeSoundFontManager.selectedIndex = indexPath.row
    }
}
