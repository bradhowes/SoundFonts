// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

final class TagsTableViewManager: NSObject {
    private lazy var log = Logging.logger("TagsTVM")

    private let view: UITableView
    private var tags = ["All", "Percussion", "Strings", "Keys", "Horns"]

    init(view: UITableView) {
        self.view = view
        super.init()
        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
    }
}

extension TagsTableViewManager {
    func selectTags(_ tags: [String]) {

    }
}

// MARK: - UITableViewDataSource Protocol

extension TagsTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tags.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
    }
}

// MARK: - UITableViewDelegate Protocol

extension TagsTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // selectedSoundFontManager.setSelected(soundFonts.getBy(index: indexPath.row))
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
}

extension TagsTableViewManager {

    private func getIndexPath(of row: Int) -> IndexPath { IndexPath(row: row, section: 0) }

    private func selectAndShow(row: Int) {
        let indexPath = getIndexPath(of: row)
        view.performBatchUpdates({self.view.selectRow(at: indexPath, animated: true, scrollPosition: .none)},
                                 completion: {_ in self.view.scrollToRow(at: indexPath, at: .none, animated: true)})
    }

    private func update(row: Int?) {
        guard let row = row else { return }
        os_log(.info, log: log, "update - row %d", row)
        let indexPath = getIndexPath(of: row)
        if let cell: TableCell = view.cellForRow(at: indexPath) {
            os_log(.info, log: log, "updating row %d", row)
            update(cell: cell, indexPath: indexPath)
        }
    }

    @discardableResult
    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        cell.updateForTag(name: tags[indexPath.row], isActive: true)
        return cell
    }
}
