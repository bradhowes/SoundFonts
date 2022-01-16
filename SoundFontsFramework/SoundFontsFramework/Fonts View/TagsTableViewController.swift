// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/// Manages the table view that appears off of the preset editor. Allows full editing of the tags collection.
public final class TagsTableViewController: UITableViewController {
  private lazy var log = Logging.logger("TagsTableViewController")

  private enum Action {
    case editTagEntries
    case editTagName(indexPath: IndexPath, selected: Bool)
    case doneEditing
  }

  /**
   Configuration for the controller that is passed to it via the segue that makes it appear.
   */
  public struct Config {
    /// The collection of all of the tags that exist for the app
    let tags: Tags
    /// The set of tags that are currently active for the sound font
    let active: Set<Tag.Key>?
    /// True if the sound font being edited is built-in
    let builtIn: Bool
    /// The method to invoke when the controller is dismissed
    let completionHandler: ((Set<Tag.Key>) -> Void)?

    init(tags: Tags, active: Set<Tag.Key>, builtIn: Bool, completionHandler: @escaping (Set<Tag.Key>) -> Void) {
      self.tags = tags
      self.active = active
      self.builtIn = builtIn
      self.completionHandler = completionHandler
    }

    init(tags: Tags) {
      self.tags = tags
      self.active = nil
      self.builtIn = false
      self.completionHandler = nil
    }
  }

  @IBOutlet private var cancelButton: UIBarButtonItem!
  @IBOutlet private var addButton: UIBarButtonItem!
  @IBOutlet private var editButton: UIBarButtonItem!
  @IBOutlet private var doneButton: UIBarButtonItem!

  private var tags: Tags!
  private var active = Set<Tag.Key>()
  private var builtIn: Bool = false
  private var selectable: Bool = true
  private var completionHandler: ((Set<Tag.Key>) -> Void)?

  private var currentAction: Action = .doneEditing {
    didSet { updateButtons() }
  }

  /**
   Configure the editor.
   */
  func configure(_ config: Config) {
    self.active.removeAll()
    self.tags = config.tags
    self.builtIn = config.builtIn
    self.selectable = config.active != nil
    self.completionHandler = config.completionHandler

    if let active = config.active {
      for tag in active {
        if !Tag.stockTagSet.contains(tag) {
          self.active.insert(tag)
        }
      }

      // We are appearing from the FontEditor controller
      navigationItem.leftBarButtonItem = nil
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(TableCell.self)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableView.automaticDimension

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
    completionHandler?(active)
  }
}

extension TagsTableViewController {

  @IBAction public func dismiss(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true)
    AskForReview.maybe()
  }

  /**
   Create a new tag.

   - parameter sender: the source of the action
   */
  @IBAction public func addTag(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "addTag")
    let indexPath = IndexPath(row: tags.append(Tag(name: Formatters.strings.newTagName)), section: 0)
    tableView.insertRows(at: [indexPath], with: .automatic)
    startEditingName(indexPath, selected: true)
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

    startEditingName(indexPath, selected: false)
  }

  /**
   Toggle editing mode. If not editing anything, begin editing the table rows.

   - parameter sender: the source of the action
   */
  @IBAction public func beginTagEditing(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "toggleTagEditing")
    switch currentAction {
    case .doneEditing: currentAction = .editTagEntries
    case .editTagEntries: currentAction = .doneEditing
    case .editTagName: stopEditingName()
    }
  }

  @IBAction public func endTagEditing(_ sender: UIBarButtonItem) {
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
    case let .editTagName(indexPath, _): return indexPath
    default: return nil
    }
  }

  private func updateButtons() {
    switch currentAction {
    case .editTagEntries:
      os_log(.debug, log: log, "updateButtons - editing rows")
      navigationItem.setRightBarButtonItems([doneButton], animated: true)
      tableView.setEditing(true, animated: true)

    case .editTagName:
      os_log(.debug, log: log, "updateButtons - editing tag name")
      navigationItem.setRightBarButtonItems([doneButton], animated: true)

    case .doneEditing:
      os_log(.debug, log: log, "updateButtons - done editing")
      editButton.isEnabled = tags.count > 2
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

  private func startEditingName(_ indexPath: IndexPath, selected: Bool) {
    os_log(.debug, log: log, "startEditingName - row: %d", indexPath.row)
    currentAction = .editTagName(indexPath: indexPath, selected: selected)
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
    guard selectable else { return }

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

  override public func tableView(_ tableView: UITableView,
                                 editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    let tag = tags.getBy(index: indexPath.row)
    if tag.key == Tag.allTag.key || tag.key == Tag.builtInTag.key {
      return .none
    }
    return .delete
  }

  override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    let tag = tags.getBy(index: indexPath.row)
    if tag.key == Tag.allTag.key || tag.key == Tag.builtInTag.key {
      return false
    }
    return true
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
      tableView.performBatchUpdates {
        active.remove(tags.remove(at: indexPath.row).key)
        tableView.deleteRows(at: [indexPath], with: .automatic)
      } completion: { _ in
        if self.tags.count <= 2 {
          self.currentAction = .doneEditing
        }
      }
    }
  }
}

extension TagsTableViewController: Tasking {

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let tag = tags.getBy(index: indexPath.row)

    if case let .editTagName(editIndexPath, selected) = currentAction, editIndexPath == indexPath {
      cell.name.isHidden = true
      cell.tagEditor.isHidden = false
      cell.tagEditor.isEnabled = true
      cell.tagEditor.delegate = self
      cell.tagEditor.text = tag.name
      Self.onMain {
        cell.tagEditor.becomeFirstResponder()
        if selected {
          cell.tagEditor.selectAll(nil)
        }
      }
    } else {
      cell.name.isHidden = false
      cell.tagEditor.isHidden = true
      cell.tagEditor.isEnabled = false
      cell.tagEditor.delegate = nil
    }

    var flags: TableCell.Flags = .init()
    if selectable {
      if tag == Tag.allTag || active.contains(tag.key) || (self.builtIn && tag == Tag.builtInTag) {
        flags.insert(.active)
      }
    }

    cell.updateForTag(at: indexPath, name: tag.name, flags: flags)
    return cell
  }
}

extension TagsTableViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {

  /**
   Notification that the font editor is being dismissed. Treat as a close.
   */
  public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    dismiss(cancelButton)
  }

  /**
   Notification that the font editor is being dismissed. Treat as a close.
   */
  public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    dismiss(cancelButton)
  }
}
