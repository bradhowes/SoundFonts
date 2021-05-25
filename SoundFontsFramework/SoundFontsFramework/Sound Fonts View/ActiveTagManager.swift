// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Tracks and manages the active tag.
 */
final class ActiveTagManager: NSObject {
    private let log = Logging.logger("ActiveTagManager")
    private let view: UITableView
    private let tags: Tags
    private var token: SubscriberToken?
    private var activeIndex = -1
    private var tagsHider: () -> Void

    init(view: UITableView, tags: Tags, tagsHider: @escaping () -> Void) {
        self.view = view
        self.tags = tags
        self.tagsHider = tagsHider
        super.init()

        token = tags.subscribe(self) { _ in self.refresh() }

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
    }

    public func refresh() {
        guard tags.restored else { return }
        activeIndex = Settings.shared.activeTagIndex
        view.reloadData()
    }
}

extension ActiveTagManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (tags.restored ? tags.count : 0) + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
    }
}

extension ActiveTagManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldIndexPath = IndexPath(row: activeIndex, section: 0)
        activeIndex = indexPath.row
        tableView.reloadRows(at: [oldIndexPath, indexPath], with: .automatic)
        Settings.shared.activeTagIndex = activeIndex
    }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
}

extension ActiveTagManager {

    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        let row = indexPath.row
        let tag = row == 0 ? LegacyTag.allTag : tags.getBy(index: row - 1)
        let name = tag.name
        cell.updateForTag(name: name, isActive: activeIndex == row)
        return cell
    }
}
