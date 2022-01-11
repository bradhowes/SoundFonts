// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Manages the table view that appears off of the preset editor. Allows full editing of the tags collection.
public final class TagsTableViewController: UITableViewController {
  private lazy var log = Logging.logger("TagsTableViewController")

  private enum Action {
    case editTagEntries
    case editTagName(indexPath: IndexPath)
    case doneEditing
  }

  /**
   Configuration for the controller that is passed to it via the segue that makes it appear.
   */
  public struct Config {
    /// The collection of all of the tags that exist for the app
    let tags: Tags
    /// The set of tags that are currently active for the sound font
    let active: Set<Tag.Key>
    /// True if the sound font being edited is built-in
    let builtIn: Bool
    /// The method to invoke when the controller is dismissed
    let completionHandler: (Set<Tag.Key>) -> Void
  }

  @IBOutlet private var addButton: UIBarButtonItem!
  @IBOutlet private var editButton: UIBarButtonItem!

  private var tags: Tags!
  private var active = Set<Tag.Key>()
  private var builtIn: Bool = false
  private var completionHandler: ((Set<Tag.Key>) -> Void)!

  private var currentAction: Action = .doneEditing {
    didSet { updateButtons() }
  }

  /**
   Configure the view.
   */
  func configure(_ config: Config) {
    self.active.removeAll()
    self.tags = config.tags
    self.builtIn = config.builtIn
    self.completionHandler = config.completionHandler
    for tag in config.active {
      if !Tag.stockTagSet.contains(tag) {
        self.active.insert(tag)
      }
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(TableCell.self)

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(editTagName(_:)))
    longPressGesture.minimumPressDuration = 0.5
    tableView.addGestureRecognizer(longPressGesture)
  }

  override public func viewWillAppear(_ animated: Bool) {
    os_log(.debug, log: log, "viewWillAppear")
    super.viewWillAppear(animated)
    currentAction = .doneEditing
  }

  override public func viewWillDisappear(_ animated: Bool) {
    os_log(.debug, log: log, "viewWillDisappear")
    stopEditingName()
    super.viewWillDisappear(animated)
    completionHandler(active)
  }
}

extension TagsTableViewController {

  /**
   Create a new tag.

   - parameter sender: the source of the action
   */
  @IBAction public func addTag(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "addTag")
    let indexPath = IndexPath(
      row: tags.append(Tag(name: Formatters.strings.newTagName)), section: 0)
    tableView.insertRows(at: [indexPath], with: .automatic)
    startEditingName(indexPath)
  }

  @IBAction public func editTagName(_ sender: UILongPressGestureRecognizer) {
    os_log(.debug, log: log, "editTagName")
    guard case .doneEditing = currentAction,
          let indexPath = self.tableView.indexPathForRow(at: sender.location(in: tableView)),
          sender.state == .began,
          !Tag.stockTagSet.contains(tags.getBy(index: indexPath.row).key)
    else {
      return
    }

    startEditingName(indexPath)
  }

  /**
   Toggle editing mode. If not editing anything, begin editing the table rows.

   - parameter sender: the source of the action
   */
  @IBAction public func toggleTagEditing(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "toggleTagEditing")
    switch currentAction {
    case .doneEditing: currentAction = .editTagEntries
    case .editTagEntries: currentAction = .doneEditing
    case .editTagName: stopEditingName()
    }
  }
}

extension TagsTableViewController: UITextFieldDelegate {

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    os_log(.debug, log: log, "textFieldShouldReturn")
    textField.resignFirstResponder()
    return true
  }

  public func textFieldDidEndEditing(_ textField: UITextField) {
    os_log(.debug, log: log, "textFieldDidEndEditing")
    stopEditingName()
  }
}

extension TagsTableViewController {

  private var activeNameEditor: IndexPath? {
    switch currentAction {
    case let .editTagName(indexPath): return indexPath
    default: return nil
    }
  }

  private func updateButtons() {
    switch currentAction {
    case .editTagEntries:
      os_log(.debug, log: log, "updateButtons - editing rows")
      editButton.title = Formatters.strings.doneButton
      editButton.isEnabled = true
      navigationItem.setRightBarButtonItems([editButton], animated: true)
      tableView.setEditing(true, animated: true)

    case .editTagName:
      os_log(.debug, log: log, "updateButtons - editing tag name")
      editButton.title = Formatters.strings.doneButton
      editButton.isEnabled = true
      navigationItem.setRightBarButtonItems([editButton], animated: true)

    case .doneEditing:
      os_log(.debug, log: log, "updateButtons - done editing")
      editButton.title = Formatters.strings.editButton
      editButton.isEnabled = !tags.isEmpty
      navigationItem.setRightBarButtonItems([editButton, addButton], animated: true)
      if tableView.isEditing {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
          self.tableView.reloadData()
        }
        tableView.setEditing(false, animated: true)
        CATransaction.commit()
      }
    }
  }

  private func startEditingName(_ indexPath: IndexPath) {
    os_log(.debug, log: log, "startEditingName - row: %d", indexPath.row)
    currentAction = .editTagName(indexPath: indexPath)
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }

  private func stopEditingName() {
    os_log(.debug, log: log, "stopEditingName")
    guard let indexPath = activeNameEditor else {
      os_log(.debug, log: log, "not editing name")
      return
    }

    currentAction = .doneEditing

    guard let cell = tableView.cellForRow(at: indexPath) as? TableCell else { fatalError() }
    if let text = cell.tagEditor.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
      os_log(.debug, log: log, "new tag name: '%{public}s'", text)
      tags.rename(indexPath.row, name: text)
      let tag = tags.getBy(index: indexPath.row)
      active.insert(tag.key)
      tableView.reloadRows(at: [indexPath], with: .automatic)
      cell.tagEditor.resignFirstResponder()
    }
  }
}

extension TagsTableViewController {

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tags.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }

  override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    os_log(.debug, log: log, "tableView:didSelectRow")
    if activeNameEditor != nil {
      stopEditingName()
      return
    }

    let tag = tags.getBy(index: indexPath.row)
    if Tag.stockTagSet.contains(tag.key) {
      tableView.deselectRow(at: indexPath, animated: true)
      return
    }

    if active.contains(tag.key) {
      active.remove(tag.key)
    } else {
      active.insert(tag.key)
    }

    tableView.deselectRow(at: indexPath, animated: true)
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }

  //    override public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
  //        let tag = tags.getBy(index: indexPath.row)
  //        active.remove(tag.key)
  //        tableView.reloadRows(at: [indexPath], with: .automatic)
  //    }

  override public func tableView(_ tableView: UITableView,
                                 editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    let tag = tags.getBy(index: indexPath.row)
    if tag.key == Tag.allTag.key || tag.key == Tag.builtInTag.key {
      return .none
    }
    return .delete
  }

  override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                                 to destinationIndexPath: IndexPath) {
    tags.insert(tags.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
  }

  override public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                                 forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      active.remove(tags.remove(at: indexPath.row).key)
      tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    currentAction = .doneEditing
  }
}

extension TagsTableViewController {

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let tag = tags.getBy(index: indexPath.row)

    if activeNameEditor == indexPath {
      cell.name.isHidden = true
      cell.tagEditor.isHidden = false
      cell.tagEditor.isEnabled = true
      cell.tagEditor.delegate = self
      cell.tagEditor.text = tag.name
      DispatchQueue.main.async { cell.tagEditor.becomeFirstResponder() }
    } else {
      cell.name.isHidden = false
      cell.tagEditor.isHidden = true
      cell.tagEditor.isEnabled = false
      cell.tagEditor.delegate = nil
    }

    let isActive = tag == Tag.allTag || active.contains(tag.key) || (self.builtIn && tag == Tag.builtInTag)
    cell.updateForTag(name: tag.name, active: isActive ? .yes : .no)

    return cell
  }
}
