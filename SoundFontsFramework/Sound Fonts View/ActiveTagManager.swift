// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/**
 <#Describe TagsTableViewManager#>
 */
final class ActiveTagManager: NSObject {
    private lazy var log = Logging.logger("TagsTVM")

    private let view: UITableView
    private let tagsManager: LegacyTagsManager
    private var token: SubscriberToken?
    private var activeIndex = -1
    private var tagsHider: () -> Void

    init(view: UITableView, tagsManager: LegacyTagsManager, tagsHider: @escaping () -> Void) {
        self.view = view
        self.tagsManager = tagsManager
        self.tagsHider = tagsHider
        super.init()

        token = tagsManager.subscribe(self) { _ in self.refresh() }

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
    }

    public func refresh() {
        guard tagsManager.restored else { return }
        activeIndex = Settings.shared.activeTagIndex
        view.reloadData()
    }
}

extension ActiveTagManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (tagsManager.restored ? tagsManager.count : 0) + 1
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
        let tag = row == 0 ? LegacyTag.allTag : tagsManager.getBy(index: row - 1)
        let name = tag.name
        cell.updateForTag(name: name, isActive: activeIndex == row)
        return cell
    }
}
