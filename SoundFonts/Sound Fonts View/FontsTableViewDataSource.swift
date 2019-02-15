//
//  SoundFontsTableDataSource.swift
//  SoundFonts
//
//  Created by Brad Howes on 12/27/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import UIKit

/**
 Data source for the SoundFont UITableView. This view shows all of the names of the SoundFont files that are available
 in the app.
 */
final class FontsTableViewDataSource: NSObject {

    let view: UITableView
    let searchBar: UISearchBar
    let activeSoundFontManager: ActiveSoundFontManager

    init(view: UITableView, searchBar: UISearchBar, activeSoundFontManager: ActiveSoundFontManager) {
        self.view = view
        self.searchBar = searchBar
        self.activeSoundFontManager = activeSoundFontManager
        super.init()
        
        view.register(FontCell.self)
        view.dataSource = self
        view.delegate = self
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
     Update a row in the table view. Note that actual updating only takes place if row is visible.
    
     - parameter index: the index to update
     */
    func refreshRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        if let cell: FontCell = view.cellForRow(at: indexPath) {
            updateCell(at: indexPath, cell: cell)
        }
    }

    /**
     Update a cell at a given row, and with the given FontCell instance.
    
     - parameter indexPath: location of row to update
     - parameter cell: FontCell to use for the update
     */
    private func updateCell(at indexPath: IndexPath, cell: FontCell) {
        cell.update(name: SoundFont.keys[indexPath.row],
                    isSelected: view.indexPathForSelectedRow == indexPath,
                    isActive: indexPath.row == activeSoundFontManager.activeIndex)
    }
}

// MARK: - UITableViewDataSource Protocol
extension FontsTableViewDataSource: UITableViewDataSource {
    
    /**
     Provide the number of sections in the table view
    
     - parameter tableView: the view to operate on
     - returns: always 1
     */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /**
     Provide the number of rows in the table view
    
     - parameter tableView: the view to operate on
     - parameter section: the section to operate on
     - returns: number of available SoundFont files
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SoundFont.keys.count
    }

    /**
     Provide a formatted FontCell for the table view
    
     - parameter tableView: the view to operate on
     - parameter indexPath: the position (row) of the cell to return
     - returns: FontCell instance to display
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FontCell = tableView.dequeueReusableCell(for: indexPath)
        updateCell(at: indexPath, cell: cell)
        return cell
    }
}

// MARK: - UITableViewDelegate Protocol
extension FontsTableViewDataSource: UITableViewDelegate {

    /**
     Notification that the user selected a sound font.
    
     - parameter tableView: the view to operate on
     - parameter indexPath: the location that was selected
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activeSoundFontManager.selectedIndex = indexPath.row
    }
}
