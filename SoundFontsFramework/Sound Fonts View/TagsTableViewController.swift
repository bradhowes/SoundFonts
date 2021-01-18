// Copyright © 2018 Brad Howes. All rights reserved.

import UIKit
import os

public final class TagsTableViewController: UITableViewController {
    private lazy var log = Logging.logger("TagsTVC")

    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!

    public struct Config {
        let tagsManager: LegacyTagsManager
        let active: [LegacyTag.Key]
        let completionHandler: (([LegacyTag.Key]?) -> Void)?
    }

    private var tagsManager: LegacyTagsManager!
    private var active = Set<Int>()
    private var completionHandler: (([LegacyTag.Key]?) -> Void)?

    private var editingRow: Int?

    override public func viewDidLoad() {
        super.viewDidLoad()
        addButton.isEnabled = true
        tableView.register(TableCell.self)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let keys = active.map { tagsManager.getBy(index: $0).key }
        completionHandler?(keys)
    }

    @IBAction public func addTag(_ sender: UIBarButtonItem) {
        let editingRow = tagsManager.add(tag: LegacyTag(name: "New Tag"))
        self.editingRow = editingRow
        addButton.isEnabled = false
        tableView.insertRows(at: [IndexPath(row: editingRow, section: 0)], with: .automatic)
    }

    @IBAction public func editTags(_ sender: UIBarButtonItem) {

    }
}

extension TagsTableViewController {

    func configure(_ config: Config) {
        active.removeAll()
        tagsManager = config.tagsManager
        completionHandler = config.completionHandler
        if config.active.isEmpty {
            active.insert(0)
        }
        else {
            for tag in config.active {
                guard let row = tagsManager.index(of: tag) else {
                    print("unknown tag - \(tag)")
                    continue
                }
                active.insert(row)
            }
        }

        for row in active {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
    }
}

extension TagsTableViewController {

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tagsManager.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        update(cell: tableView.dequeueReusableCell(at: indexPath), indexPath: indexPath)
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        active.insert(indexPath.row)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    override public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        active.remove(indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    private func update(cell: TableCell, indexPath: IndexPath) -> TableCell {
        let tag = tagsManager.getBy(index: indexPath.row)

        if editingRow == indexPath.row {
            cell.name.isHidden = true
            cell.tagEditor.isHidden = false
            cell.tagEditor.isEnabled = true
            cell.tagEditor.delegate = self
            cell.tagEditor.text = tag.name
            cell.tagEditor.becomeFirstResponder()
        }
        else {
            cell.name.isHidden = false
            cell.tagEditor.isHidden = true
            cell.tagEditor.isEnabled = false
            cell.tagEditor.delegate = nil
        }

        cell.updateForTag(name: tag.name, isActive: active.contains(indexPath.row))
        return cell
    }
}

extension TagsTableViewController: UITextFieldDelegate {

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print("textFieldShouldReturn")
        return true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        print("\(textField.text ?? "nil")")
        guard let row = editingRow else { fatalError("nil editingRow")}
        addButton.isEnabled = true
        editingRow = nil
        if let text = textField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
            tagsManager.rename(index: row, name: text)
            tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        }
        else {
            _ = tagsManager.remove(index: row)
            tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .fade)
        }
    }
}
