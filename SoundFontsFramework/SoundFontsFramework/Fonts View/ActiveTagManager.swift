// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os

/// The event notifications that can come from an ActiveTagManager subscription.
public enum ActiveTagEvent: CustomStringConvertible {

  /**
   Change event

   - Parameter old: the previous active tag
   - Parameter new: the new active tag
   */
  case change(old: Tag, new: Tag)

  public var description: String {
    switch self {
    case let .change(old, new): return "<ActiveTagEvent: change old: \(old) new: \(new)>"
    }
  }
}

/**
 Tracks and manages the active tag. It also serves as the data source and delegate for the tags table view.
 */
final class ActiveTagManager: SubscriptionManager<ActiveTagEvent>, Tasking {
  private lazy var log = Logging.logger("ActiveTagManager")
  private let viewController: SoundFontsViewController
  private let tableView: UITableView
  private let tags: Tags
  private let settings: Settings
  private var token: SubscriberToken?
  private var activeIndex = -1
  private var tagsHider: () -> Void

  init(viewController: SoundFontsViewController, tableView: UITableView, tags: Tags, settings: Settings,
       tagsHider: @escaping () -> Void) {
    self.viewController = viewController
    self.tableView = tableView
    self.tags = tags
    self.settings = settings
    self.tagsHider = tagsHider
    super.init()

    tableView.register(TableCell.self)
    tableView.dataSource = self
    tableView.delegate = self

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    longPressGesture.minimumPressDuration = 0.5
    tableView.addGestureRecognizer(longPressGesture)

    token = tags.subscribe(self, notifier: tagsChanged_BT)
    refresh()
  }

  public func showActiveTag(animated: Bool) {
    tableView.scrollToRow(at: IndexPath(row: activeIndex, section: 0), at: .none, animated: animated)
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
    let oldTag = tags.getBy(index: activeIndex)
    activeIndex = indexPath.row
    let newTag = tags.getBy(index: activeIndex)

    tableView.reloadRows(at: [oldIndexPath, indexPath], with: .automatic)
    notify(.change(old: oldTag, new: newTag))
    settings.activeTagKey = newTag.key
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }
}

extension ActiveTagManager {

  private func tagsChanged_BT(_ event: TagsEvent) {
    Self.onMain { self.refresh() }
  }

  @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
      let config = TagsTableViewController.Config(tags: tags)
      viewController.performSegue(withIdentifier: .tagsEditor, sender: config)
    }
  }

//  private func prepareToEdit(_ segue: UIStoryboardSegue) {
//    guard let viewController = segue.destination as? TagsTableViewController else {
//      fatalError("unexpected view configuration")
//    }
//
//    let config = TagsTableViewController.Config(tags: self.config.tags, active: activeTags,
//                                                builtIn: soundFont.kind.resource) { [weak self] tags in
//      self?.activeTags = tags
//    }
//
//    viewController.configure(config)
//  }

  private func refresh() {
    guard tags.restored else { return }
    let tagKey = settings.activeTagKey
    activeIndex = tags.index(of: tagKey) ?? 0
    tableView.reloadData()
  }

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let row = indexPath.row
    let tag = tags.getBy(index: row)
    let name = tag.name
    var flags: TableCell.Flags = .init()
    if activeIndex == row { flags.insert(.active) }
    cell.updateForTag(at: indexPath, name: name, flags: flags)
    return cell
  }
}
