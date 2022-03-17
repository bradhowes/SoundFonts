// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit
import os.log

/**
 The view controller for the tags table. Display data comes from the tags collection  The controller
 allows for setting the active tag, a value maintained by the ActiveTagManager.
 */
final class TagsTableViewController: UITableViewController, Tasking {

  private var tags: Tags!
  private var activeTagManager: ActiveTagManager!

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(TableCell.self)
    tableView.dataSource = self
    tableView.delegate = self

    tableView.isAccessibilityElement = false
    tableView.accessibilityIdentifier = "TagsTableList"
    tableView.accessibilityHint = "List of tags for filtering fonts"
    tableView.accessibilityLabel = "TagsTableList"

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    longPressGesture.minimumPressDuration = 0.5
    tableView.addGestureRecognizer(longPressGesture)
  }
}

extension TagsTableViewController {

  /**
   Make sure that the active tag is visible in the table view.
   */
  func scrollToActiveRow() {
    guard let tags = self.tags,
          let activeTagManager = self.activeTagManager,
          let row = tags.index(of: activeTagManager.activeTag.key) else { return }
    self.tableView.scrollToRow(at: row.indexPath, at: .none, animated: true)
  }
}

extension TagsTableViewController: ControllerConfiguration {

  func establishConnections(_ router: ComponentContainer) {
    tags = router.tags
    tags.subscribe(self, notifier: tagsRestored_BT)

    activeTagManager = router.activeTagManager
    activeTagManager.subscribe(self, notifier: activeTagChanged_BT)

    refresh()
  }
}

// MARK: - UITableViewDataSource

extension TagsTableViewController {

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    (tags != nil && tags.isRestored) ? tags.count : 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }
}

// MARK: - UITableViewDelegate

extension TagsTableViewController {

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    activeTagManager.setActiveTag(index: indexPath.row)
  }

  override func tableView(_ tableView: UITableView,
                          editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }
}

extension TagsTableViewController {

  private func tagsRestored_BT(_ event: TagsEvent) {
    Self.onMain { self.refresh() }
  }

  private func activeTagChanged_BT(_ event: ActiveTagEvent) {
    if case let .change(oldTag, newTag) = event {
      Self.onMain { self.handleTagChange(oldTag, newTag) }
    } else {
      Self.onMain { self.refresh() }
    }
  }

  @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
      let config = TagsEditorTableViewController.Config(tags: tags)
      guard let parent = parent as? SoundFontsViewController else { fatalError() }
      parent.performSegue(withIdentifier: .tagsEditor, sender: config)
    }
  }

  private func handleTagChange(_ oldTag: Tag?, _ newTag: Tag) {
    if let oldTag = oldTag {
      let rows = [oldTag, newTag].compactMap { tags.index(of: $0.key) }
      let indexPaths = rows.map { $0.indexPath }
      if !indexPaths.isEmpty {
        tableView.reloadRows(at: indexPaths, with: .automatic)
      }
    } else {
      tableView.reloadData()
    }
  }

  private func refresh() {
    guard tags.isRestored else { return }
    tableView.reloadData()
  }

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let row = indexPath.row
    let tag = tags.getBy(index: row)
    let name = tag.name
    var flags: TableCell.Flags = .init()
    if activeTagManager.activeTag == tag { flags.insert(.active) }
    cell.updateForTag(at: indexPath, name: name, flags: flags)
    return cell
  }
}

fileprivate extension Int {

  /// Sugar to create an IndexPath from a row value.
  var indexPath: IndexPath { IndexPath(row: self, section: 0) }
}
