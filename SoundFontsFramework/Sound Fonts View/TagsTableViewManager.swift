// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

final class TagsTableViewManager: NSObject {
    private lazy var log = Logging.logger("TagsTVM")

    private let view: UITableView
    private let tagsManager: LegacyTagsManager
    private var token: SubscriberToken?
    private var active = Set<Int>()

    init(view: UITableView, tagsManager: LegacyTagsManager) {
        self.view = view
        self.tagsManager = tagsManager
        super.init()

        token = tagsManager.subscribe(self) { _ in
            if tagsManager.restored {
                self.refresh()
            }
        }

        view.register(TableCell.self)
        view.dataSource = self
        view.delegate = self
    }

    public func refresh() {
        active.removeAll()
        for key in Settings.shared.activeTags {
            if let row = tagsManager.index(of: key) {
                active.insert(row)
            }
        }

        view.reloadData()

        for row in active {
            view.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
    }
}

extension TagsTableViewManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tagsManager.restored ? tagsManager.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
    }
}

// MARK: - UITableViewDelegate Protocol

extension TagsTableViewManager: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if active.contains(indexPath.row) {
            active.remove(indexPath.row)
        }
        else {
            active.insert(indexPath.row)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        Settings.shared.activeTags = tagsManager.keySet(of: active)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        active.remove(indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        Settings.shared.activeTags = tagsManager.keySet(of: active)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }
}

extension TagsTableViewManager {

    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        cell.updateForTag(name: tagsManager.getBy(index: indexPath.row).name,
                          isActive: active.contains(indexPath.row))
        return cell
    }
}
