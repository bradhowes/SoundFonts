// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/// Tracks and manages the active tag.
final class ActiveTagManager: NSObject {
  private lazy var log = Logging.logger("ActiveTagManager")
  private let view: UITableView
  private let tags: Tags
  private let settings: Settings
  private var token: SubscriberToken?
  private var activeIndex = -1
  private var tagsHider: () -> Void

  init(view: UITableView, tags: Tags, settings: Settings, tagsHider: @escaping () -> Void) {
    self.view = view
    self.tags = tags
    self.settings = settings
    self.tagsHider = tagsHider
    super.init()

    token = tags.subscribe(self) { [weak self] _ in self?.refresh() }

    view.register(TableCell.self)
    view.dataSource = self
    view.delegate = self
  }

  public func refresh() {
    guard tags.restored else { return }
    let tagKey = settings.activeTagKey
    activeIndex = tags.index(of: tagKey) ?? 0
    view.reloadData()
  }

  public func showActiveTag(animated: Bool) {
    view.scrollToRow(at: IndexPath(row: activeIndex, section: 0), at: .none, animated: animated)
  }
}

extension ActiveTagManager: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int { 1 }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tags.restored ? tags.count : 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }
}

extension ActiveTagManager: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard activeIndex != indexPath.row else { return }
    let oldIndexPath = IndexPath(row: activeIndex, section: 0)
    activeIndex = indexPath.row
    tableView.reloadRows(at: [oldIndexPath, indexPath], with: .automatic)
    settings.activeTagKey = tags.getBy(index: activeIndex).key
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }
}

extension ActiveTagManager {

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let row = indexPath.row
    let tag = tags.getBy(index: row)
    let name = tag.name
    cell.updateForTag(name: name, isActive: activeIndex == row)
    return cell
  }
}
