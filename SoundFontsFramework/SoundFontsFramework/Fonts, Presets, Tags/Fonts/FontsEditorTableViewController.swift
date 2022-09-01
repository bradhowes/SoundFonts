// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 */
public final class FontsEditorTableViewController: UITableViewController {
  private lazy var log = Logging.logger("FontsEditorTableViewController")

  /// The current action being undertaken by the editor. Used to manage state transitions and UI view.
  fileprivate enum Action {
    /// Enter `edit` mode and allow creation, deletion and movement of tags.
    case editFontEntries
    /// Exit editing mode and just present the tag names
    case doneEditing
  }

  /**
   Configuration for the controller that is passed to it via the segue that makes it appear.
   */
  public struct Config {
    let fonts: SoundFontsProvider

    init(fonts: SoundFontsProvider) {
      self.fonts = fonts
    }
  }

  // NOTE: do *not* make these buttons `weak` or else they will become nil when editing mode changes.
  @IBOutlet private var cancelButton: UIBarButtonItem!
  @IBOutlet private var editButton: UIBarButtonItem!
  @IBOutlet private var doneButton: UIBarButtonItem!

  private var fonts: SoundFontsProvider!
  private var currentAction: Action = .doneEditing { didSet { updateButtons() } }

  /**
   Configure the editor with given attributes

   - parameter config: the configuration to apply
   */
  func configure(_ config: Config) {
    self.fonts = config.fonts
    currentAction = .doneEditing
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(TableCell.self)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableView.automaticDimension
  }

  override public func viewWillDisappear(_ animated: Bool) {
    os_log(.debug, log: log, "viewWillDisappear")
    super.viewWillDisappear(animated)
  }
}

extension FontsEditorTableViewController {

  @IBAction public func dismiss(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true)
    AskForReview.maybe()
  }

  /**
   Toggle editing mode. If not editing anything, begin editing the table rows.

   - parameter sender: the source of the action
   */
  @IBAction public func beginTagEditing(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "toggleTagEditing")
    switch currentAction {
    case .doneEditing: currentAction = .editFontEntries
    case .editFontEntries: currentAction = .doneEditing
    }
  }

  @IBAction public func endTagEditing(_ sender: UIBarButtonItem) {
    os_log(.debug, log: log, "toggleTagEditing")
    switch currentAction {
    case .doneEditing: currentAction = .editFontEntries
    case .editFontEntries: currentAction = .doneEditing
    }
  }
}

// MARK: - UITextFieldDelegate

extension FontsEditorTableViewController {

  private func updateButtons() {
    switch currentAction {
    case .editFontEntries:
      os_log(.debug, log: log, "updateButtons - editing rows")
      navigationItem.setRightBarButtonItems([doneButton], animated: true)
      tableView.setEditing(true, animated: true)

    case .doneEditing:
      os_log(.debug, log: log, "updateButtons - done editing")
      editButton.isEnabled = !fonts.isEmpty
      navigationItem.setRightBarButtonItems([editButton], animated: true)

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
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension FontsEditorTableViewController {

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    fonts.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }

  override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard !isEditing else { return }
    tableView.deselectRow(at: indexPath, animated: false)
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }

  override public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    nil
  }

  override public func tableView(_ tableView: UITableView,
                                 editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .delete
  }

  override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                                 forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      tableView.performBatchUpdates {
        fonts.remove(key: fonts.getBy(index: indexPath.row).key)
        tableView.deleteRows(at: [indexPath], with: .automatic)
      } completion: { _ in
        if self.fonts.isEmpty {
          self.currentAction = .doneEditing
        }
      }
    }
  }
}

extension FontsEditorTableViewController {

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let font = fonts.getBy(index: indexPath.row)

    // Show the normal name view
    cell.name.isHidden = false
    cell.tagEditor.isHidden = true
    cell.tagEditor.isEnabled = false
    cell.tagEditor.delegate = nil
    cell.updateForTag(at: indexPath, name: font.displayName, flags: .init())
    return cell
  }
}

extension FontsEditorTableViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {

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
