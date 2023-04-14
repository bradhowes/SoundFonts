// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 View controller that allows one to edit the defined tags for sound fonts. This controller can change the names of
 tags, create new ones, and delete existing ones. It can also change the ordering of tags, affecting the display ordering
 in the `ActiveTagManager`. This controller comes into play either from the font editor or by long pressing on a tag in
 the `ActiveTagManager` view.
 */
final class TagsEditorTableViewController: UITableViewController {
  private lazy var log = Logging.logger("TagsEditorTableViewController")

  /// The current action being undertaken by the editor. Used to manage state transitions and UI view.
  fileprivate enum Action {
    /// Enter `edit` mode and allow creation, deletion and movement of tags.
    case editTagEntries
    /// Enter renaming mode for one tag
    case editTagName(indexPath: IndexPath, selected: Bool)
    /// Exit editing mode and just present the tag names
    case doneEditing

    var activeNameEditor: IndexPath? {
      switch self {
      case .editTagName(let indexPath, _): return indexPath
      default: return nil
      }
    }
  }

  /**
   Configuration for the controller that is passed to it via the segue that makes it appear.
   */
  struct Config {
    /// The collection of all of the tags that exist for the app
    let tags: TagsProvider
    /// The set of tags that are currently active for the sound font
    let active: Set<Tag.Key>?
    /// True if the sound font being edited is built-in
    let builtIn: Bool
    /// The method to invoke when the controller is dismissed
    let completionHandler: ((Set<Tag.Key>) -> Void)?

    /**
     Constructor for editing the tags of a sound font.

     - parameter tags: the tags that currently exist
     - parameter active: the set of tags associated with the sound font
     - parameter builtIn: true if the sound font is a builtin one
     - parameter completionHandler: completion handler that receives a new `active` set when the editor is dismissed.
     */
    init(tags: TagsProvider, active: Set<Tag.Key>, builtIn: Bool, completionHandler: @escaping (Set<Tag.Key>) -> Void) {
      self.tags = tags
      self.active = active
      self.builtIn = builtIn
      self.completionHandler = completionHandler
    }

    /**
     Constructor for editing all of the tags

     - parameter tags: the tags that currently exist
     */
    init(tags: TagsProvider) {
      self.tags = tags
      self.active = nil
      self.builtIn = false
      self.completionHandler = nil
    }
  }

  // NOTE: do *not* make these buttons `weak` or else they will become nil when editing mode changes.
  @IBOutlet private var cancelButton: UIBarButtonItem!
  @IBOutlet private var addButton: UIBarButtonItem!
  @IBOutlet private var editButton: UIBarButtonItem!
  @IBOutlet private var doneButton: UIBarButtonItem!

  private var tags: TagsProvider!
  private var active = Set<Tag.Key>()
  private var builtIn: Bool = false
  private var selectable: Bool = true
  private var completionHandler: ((Set<Tag.Key>) -> Void)?
  private var currentAction: Action = .doneEditing { didSet { updateButtons() } }
  private var activeNameEditor: IndexPath? { currentAction.activeNameEditor }

  /**
   Configure the editor with given attributes

   - parameter config: the configuration to apply
   */
  func configure(_ config: Config) {
    self.active.removeAll()
    self.tags = config.tags
    self.builtIn = config.builtIn

    // When `active` is not nil, we are editing the tags of a specific sound font. Otherwise, we are editing all of the
    // tags. The only real difference is that in the latter case there is no `selection` involved for adding/removing
    // a sound font from tag membership.
    self.selectable = config.active != nil
    self.completionHandler = config.completionHandler

    if let active = config.active {
      for tag in active where !Tag.stockTagSet.contains(tag) {
        self.active.insert(tag)
      }

      // We are appearing from the FontEditor controller, so do not show the `Cancel` button
      navigationItem.leftBarButtonItem = nil
    }

    currentAction = .doneEditing
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(TableCell.self)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableView.automaticDimension

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(editTagName(_:)))
    longPressGesture.minimumPressDuration = 0.5
    tableView.addGestureRecognizer(longPressGesture)
  }

  override func viewWillDisappear(_ animated: Bool) {
    os_log(.debug, log: log, "viewWillDisappear")
    stopEditingName()
    super.viewWillDisappear(animated)
    completionHandler?(active)
  }
}

// MARK: - UITextFieldDelegate

extension TagsEditorTableViewController: UITextFieldDelegate {

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    os_log(.debug, log: log, "textFieldShouldReturn")
    textField.resignFirstResponder()
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    os_log(.debug, log: log, "textFieldDidEndEditing")
    stopEditingName()
  }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension TagsEditorTableViewController {

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tags.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    guard !isEditing else { return }

    if activeNameEditor != nil {
      stopEditingName()
      return
    }

    if selectable {
      let tagKey = tags.getBy(index: indexPath.row).key
      if !Tag.stockTagSet.contains(tagKey) {
        if active.contains(tagKey) {
          active.remove(tagKey)
        } else {
          active.insert(tagKey)
        }
      }
    } else {
      tableView.deselectRow(at: indexPath, animated: false)
    }

    tableView.reloadRows(at: [indexPath], with: .automatic)
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    selectable ? indexPath : nil
  }

  override func tableView(_ tableView: UITableView,
                          editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    // Do not allow the `All` tag and the `Built-in` tags to be edited.
    Tag.stockTagSet.contains(tags.getBy(index: indexPath.row).key) ? .none : .delete
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                          to destinationIndexPath: IndexPath) {
    tags.insert(tags.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
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

private extension TagsEditorTableViewController {

  @IBAction func dismiss(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true)
    AskForReview.maybe()
  }

  /**
   Create a new tag.

   - parameter sender: the source of the action
   */
  @IBAction func addTag(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "addTag")
    let indexPath = IndexPath(row: tags.append(Tag(name: Formatters.strings.newTagName)), section: 0)
    tableView.insertRows(at: [indexPath], with: .automatic)
    startEditingName(indexPath, selected: true)
  }

  @IBAction func editTagName(_ sender: UILongPressGestureRecognizer) {
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
  @IBAction func beginTagEditing(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "toggleTagEditing")
    switch currentAction {
    case .doneEditing: currentAction = .editTagEntries
    case .editTagEntries: currentAction = .doneEditing
    case .editTagName: stopEditingName()
    }
  }

  @IBAction func endTagEditing(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "toggleTagEditing")
    switch currentAction {
    case .doneEditing: currentAction = .editTagEntries
    case .editTagEntries: currentAction = .doneEditing
    case .editTagName: stopEditingName()
    }
  }

  func updateButtons() {
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

  func startEditingName(_ indexPath: IndexPath, selected: Bool) {
    os_log(.debug, log: log, "startEditingName - row: %d", indexPath.row)
    currentAction = .editTagName(indexPath: indexPath, selected: selected)
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }

  func stopEditingName() {
    os_log(.debug, log: log, "stopEditingName")
    guard let indexPath = activeNameEditor else {
      os_log(.debug, log: log, "not editing name")
      return
    }

    currentAction = .doneEditing
    guard let cell = tableView.cellForRow(at: indexPath) as? TableCell else { fatalError() }

    // Don't allow for empty tag names or ones with just whitespace characters. For now, duplicate names are OK, just a
    // bit pointless and of no real concern since tag names are not involved in anything other than display and
    // ordering.
    if let text = cell.tagEditor.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
      os_log(.debug, log: log, "new tag name: '%{public}s'", text)
      tags.rename(indexPath.row, name: text)
      let tag = tags.getBy(index: indexPath.row)
      active.insert(tag.key)
      tableView.reloadRows(at: [indexPath], with: .automatic)
      cell.tagEditor.resignFirstResponder()
    }
  }

  func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let tag = tags.getBy(index: indexPath.row)

    if case let .editTagName(editIndexPath, selected) = currentAction, editIndexPath == indexPath {

      // Show the special name editor
      cell.name.isHidden = true
      cell.tagEditor.isHidden = false
      cell.tagEditor.isEnabled = true
      cell.tagEditor.delegate = self
      cell.tagEditor.text = tag.name
      DispatchQueue.main.async {
        cell.tagEditor.becomeFirstResponder()
        if selected {
          cell.tagEditor.selectAll(nil)
        }
      }
    } else {
      // Show the normal name view
      cell.name.isHidden = false
      cell.tagEditor.isHidden = true
      cell.tagEditor.isEnabled = false
      cell.tagEditor.delegate = nil
    }

    var flags: TableCell.Flags = .init()
    if selectable {

      // Use the `active` attribute to show that the sound font is currently a member of a tag.
      if tag == Tag.allTag || active.contains(tag.key) || (self.builtIn && tag == Tag.builtInTag) {
        flags.insert(.active)
      }
    }

    cell.updateForTag(at: indexPath, name: tag.name, flags: flags)
    return cell
  }
}

extension TagsEditorTableViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {

  /**
   Notification that the font editor is being dismissed. Treat as a close.
   */
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    dismiss(cancelButton)
  }

  /**
   Notification that the font editor is being dismissed. Treat as a close.
   */
  func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    dismiss(cancelButton)
  }
}
