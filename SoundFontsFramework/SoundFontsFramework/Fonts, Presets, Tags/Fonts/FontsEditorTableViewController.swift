// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 */
final class FontsEditorTableViewController: UITableViewController {
  private lazy var log: Logger = Logging.logger("FontsEditorTableViewController")

  /**
   Configuration for the controller that is passed to it via the segue that makes it appear.
   */
  struct Config {
    let fonts: SoundFontsProvider
    let settings: Settings
  }

  // NOTE: do *not* make these buttons `weak` or else they will become nil when editing mode changes.
  @IBOutlet private var cancelButton: UIBarButtonItem!
  @IBOutlet private var trashButton: UIBarButtonItem!
  @IBOutlet private var selectAllButton: UIBarButtonItem!

  private var fonts: SoundFontsProvider!
  private var settings: Settings!
  private var selectedRows = Set<Int>()

  /**
   Configure the editor with given attributes

   - parameter config: the configuration to apply
   */
  func configure(_ config: Config) {
    self.fonts = config.fonts
    self.settings = config.settings
    self.trashButton.isEnabled = false
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    selectedRows.removeAll()
    tableView.register(TableCell.self)
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableView.automaticDimension
  }

  override func viewWillDisappear(_ animated: Bool) {
    log.debug("viewWillDisappear")
    self.trashButton.isEnabled = false
    self.selectedRows.removeAll()
    tableView.reloadData()
    super.viewWillDisappear(animated)
  }
}

// MARK: - UITableViewDataSource / UITableViewDelegate

extension FontsEditorTableViewController {

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    fonts.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // guard !isEditing else { return }

    tableView.deselectRow(at: indexPath, animated: true)

    if self.selectedRows.contains(indexPath.row) {
      self.selectedRows.remove(indexPath.row)
    } else {
      self.selectedRows.insert(indexPath.row)
      let font = fonts.getBy(index: indexPath.row)
      if !font.kind.installed {
        notifyAboutBuiltinFonts()
      }
    }

    tableView.reloadRows(at: [indexPath], with: .automatic)
    trashButton.isEnabled = !selectedRows.isEmpty
  }

  private func notifyAboutBuiltinFonts() {
    guard !settings[.notifiedAboutBuiltinFonts] else { return }
    settings[.notifiedAboutBuiltinFonts] = true

    let alertController = UIAlertController(title: "Built-in Font",
                                            message: "Deleting a built-in font only hides it from view. " +
                                            "You can restore their visibility in the Settings view",
                                            preferredStyle: .alert)
    let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in }
    alertController.addAction(cancel)

    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(
        x: self.view.bounds.midX, y: self.view.bounds.midY,
        width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    indexPath
  }

  override func tableView(_ tableView: UITableView,
                          editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    .none
  }
}

extension FontsEditorTableViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {

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

private extension FontsEditorTableViewController {

  @IBAction func dismiss(_ sender: UIBarButtonItem) {
    self.dismiss(animated: true)
    AskForReview.maybe()
  }

  @IBAction func selectAllFonts(_ sender: UIBarButtonItem) {
    if selectedRows.count == fonts.count {
      selectedRows.removeAll()
    } else {
      selectedRows.formUnion(0..<fonts.count)
    }
    tableView.reloadData()
    trashButton.isEnabled = !selectedRows.isEmpty
  }

  @IBAction func deleteFonts(_ sender: UIBarButtonItem) {
    let promptTitle = "Delete \(selectedRows.count) font\(selectedRows.count == 1 ? "" : "s")?"
    let promptMessage = "This cannot be undone."
    let alertController = UIAlertController(title: promptTitle, message: promptMessage, preferredStyle: .alert)

    let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self ] _ in
      self?.doDelete()
    }

    let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }

    alertController.addAction(delete)
    alertController.addAction(cancel)

    if let popoverController = alertController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(
        x: self.view.bounds.midX, y: self.view.bounds.midY,
        width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }

  private func doDelete() {
    let keys = selectedRows.map { fonts.getBy(index: $0).key }
    tableView.performBatchUpdates {
      for key in keys {
        guard let font = fonts.getBy(key: key) else { continue }
        fonts.remove(key: key)
        if font.kind.deletable {
          DispatchQueue.global(qos: .userInitiated).async {
            try? FileManager.default.removeItem(at: font.fileURL)
          }
        }
      }
      tableView.deleteRows(at: selectedRows.map {.init(row: $0, section: 0)}, with: .automatic)
    }
    selectedRows.removeAll()
    trashButton.isEnabled = false
  }

  private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
    let font = fonts.getBy(index: indexPath.row)

    // Show the normal name view
    cell.name.isHidden = false
    cell.tagEditor.isHidden = true
    cell.tagEditor.isEnabled = false
    cell.tagEditor.delegate = nil
    cell.accessoryType = selectedRows.contains(indexPath.row) ? .checkmark : .none
    cell.updateForTag(at: indexPath, name: font.displayName, flags: font.kind.installed ? .selected : .init())

    return cell
  }
}
