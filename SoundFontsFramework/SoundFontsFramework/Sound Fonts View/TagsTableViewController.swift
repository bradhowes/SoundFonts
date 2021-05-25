// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

/**
 Manages the table view that appears off of the preset editor. Allows full editing of the tags collection.
 */
public final class TagsTableViewController: UITableViewController {
    private lazy var log = Logging.logger("TagsTableViewController")

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!

    public struct Config {
        let tags: Tags
        let active: Set<LegacyTag.Key>
        let completionHandler: (Set<LegacyTag.Key>) -> Void
    }

    private var tags: Tags!
    private var active = Set<LegacyTag.Key>()
    private var completionHandler: ((Set<LegacyTag.Key>) -> Void)!
    private var editingRow: Int?

    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TableCell.self)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addButton.isEnabled = true
        editButton.isEnabled = !tags.isEmpty
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        completionHandler(active)
    }

    @IBAction public func addTag(_ sender: UIBarButtonItem) {
        let editingRow = tags.append(LegacyTag(name: "New Tag"))
        addButton.isEnabled = false
        editButton.isEnabled = false
        self.editingRow = editingRow
        tableView.insertRows(at: [IndexPath(row: editingRow, section: 0)], with: .automatic)
    }

    @IBAction public func editTags(_ sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        editButton.title = tableView.isEditing ? "Done" : "Edit"
    }
}

extension TagsTableViewController {

    func configure(_ config: Config) {
        active.removeAll()
        tags = config.tags
        completionHandler = config.completionHandler
        for tag in config.active {
            guard tag != LegacyTag.allTag.key else { continue }
            active.insert(tag)
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
        let tag = tags.getBy(index: indexPath.row)
        if active.contains(tag.key) {
            active.remove(tag.key)
        }
        else {
            active.insert(tag.key)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    override public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let tag = tags.getBy(index: indexPath.row)
        active.remove(tag.key)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                                   to destinationIndexPath: IndexPath) {
        let tag = tags.remove(at: sourceIndexPath.row)
        tags.insert(tag, at: destinationIndexPath.row)
    }

    override public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tag = tags.remove(at: indexPath.row)
            active.remove(tag.key)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            editButton.isEnabled = !tags.isEmpty
        }
    }

    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        let tag = tags.getBy(index: indexPath.row)

        if editingRow == indexPath.row {
            cell.name.isHidden = true
            cell.tagEditor.isHidden = false
            cell.tagEditor.isEnabled = true
            cell.tagEditor.delegate = self
            cell.tagEditor.text = tag.name
            DispatchQueue.main.async { cell.tagEditor.becomeFirstResponder() }
        }
        else {
            cell.name.isHidden = false
            cell.tagEditor.isHidden = true
            cell.tagEditor.isEnabled = false
            cell.tagEditor.delegate = nil
        }

        cell.updateForTag(name: tag.name, isActive: active.contains(tag.key))

        return cell
    }
}

extension TagsTableViewController: UITextFieldDelegate {

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let row = editingRow else { fatalError("nil editingRow")}
        addButton.isEnabled = true
        editingRow = nil
        if let text = textField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
            tags.rename(row, name: text)
            let tag = tags.getBy(index: row)
            active.insert(tag.key)
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        }
        else {
            _ = tags.remove(at: row)
            tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .fade)
        }
        editButton.isEnabled = !tags.isEmpty
    }
}
