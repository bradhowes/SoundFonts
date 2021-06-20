// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import UIKit
import os

/// Delegate protocol for a TableViewSource instance. Combines a NSFetchedResults object (`Object`) with a UITableViewCell
/// instance (`Cell`).
public protocol TableViewDataSourceDelegate: AnyObject {
  associatedtype Entity: NSFetchRequestResult
  associatedtype Cell: UITableViewCell

  /**
   Create a representation of a managed object in the given cell

   - parameter cell: the view to render into
   - parameter object: the object to render
   */
  func configure(_ cell: Cell, for object: Entity)

  /**
   Determine if this row can be deleted.

   - parameter index: row index
   - returns: true if so
   */
  func canDelete(_ index: IndexPath) -> Bool

  /**
   Delete the object at a given row.

   - parameter obj: the object to delete
   - parameter at: the row the object is in
   */
  func delete(_ obj: Entity, at: IndexPath)

  /**
   Notification that the table was updated due to NSFetchResultsController activity
   */
  func updated()
}

/// A data source for a UITableView that relies on a NSFetchedResultsController for model values. This design was heavily
/// based on code from obj.io Core Data book.
public class TableViewDataSource<Delegate: TableViewDataSourceDelegate>: NSObject,
                                                                         UITableViewDataSource,
                                                                         NSFetchedResultsControllerDelegate
{
  private lazy var log = Logging.logger("tvds")

  public typealias Entity = Delegate.Entity
  public typealias Cell = Delegate.Cell

  private let tableView: UITableView
  private let cellIdentifier: String
  private let fetchedResultsController: NSFetchedResultsController<Entity>
  private weak var delegate: Delegate!  // Lifetime is always as long as that of the delegate.

  /// Obtain the managed object for the currently selected row
  public var selectedObject: Entity? {
    guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
    return object(at: indexPath)
  }

  /**
   Construct a new instance.

   - parameter tableView: the UITableView that will show the rendered model instances
   - parameter cellIdentifier: the identifier of the UITableViewCell to use for rendering
   - parameter fetchedResultsController: the source of model instances from Core Data
   - parameter delegate: the delegate for rendering and deletion handling
   */
  public required init(
    tableView: UITableView, cellIdentifier: String,
    fetchedResultsController: NSFetchedResultsController<Entity>, delegate: Delegate
  ) {
    self.tableView = tableView
    self.cellIdentifier = cellIdentifier
    self.fetchedResultsController = fetchedResultsController
    self.delegate = delegate
    super.init()

    os_log(.info, log: log, "init")

    fetchedResultsController.delegate = self
    guard (try? fetchedResultsController.performFetch()) != nil else { fatalError() }

    tableView.dataSource = self
    tableView.reloadData()
  }

  /// Obtain the number of model instances, or the number of rows in the UITableView.
  public var count: Int { fetchedResultsController.fetchedObjects?.count ?? 0 }

  /**
   Obtain the model instance for a given UITableView row.

   - parameter indexPath: the row to fetch
   - returns: the found model instance
   */
  public func object(at indexPath: IndexPath) -> Entity {
    fetchedResultsController.object(at: indexPath)
  }

  /**
   Change an existing Core Data fetch request and execute it.

   - parameter configure: block to run to edit the request
   */
  public func reconfigureFetchRequest(_ configure: (NSFetchRequest<Entity>) -> Void) {
    NSFetchedResultsController<NSFetchRequestResult>.deleteCache(
      withName: fetchedResultsController.cacheName)
    configure(fetchedResultsController.fetchRequest)
    do { try fetchedResultsController.performFetch() } catch { fatalError("fetch request failed") }
    tableView.reloadData()
  }

  // MARK: - UITableViewDataSource

  /**
   Query for the number of rows in a table view section.

   - parameter tableView: the UITableView being asked about
   - parameter section: the section being asked about
   - returns: row count in the section
   */
  public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let section = fetchedResultsController.sections?[section] else { return 0 }
    return section.numberOfObjects
  }

  /**
   Obtain a formatted UITableViewCell for a specific row in a table view. The delegate's `configure` method performs
   the necessary configuration on the cell before it is used.

   - parameter tableView: the UITableView being worked on
   - parameter indexPath: the index of the row being displayed
   - returns: the UITableViewCell to use to display the row
   */
  public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
  -> UITableViewCell
  {
    let obj = object(at: indexPath)
    guard
      let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        as? Cell
    else {
      fatalError("unexpected cell type at \(indexPath)")
    }
    delegate.configure(cell, for: obj)
    return cell
  }

  /**
   Query to find out if a row in a table view can be edited.

   - parameter tableView: the UITableView being worked on
   - parameter indexPath: the index of the row being asked about
   - returns: true if so
   */
  public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return self.delegate.canDelete(indexPath)
  }

  /**
   Perform an edit action on a specific row

   - parameter tableView: the UITableView being worked on
   - parameter editingStyle: the operation being performed. The only one supported is `.delete`
   - parameter indexPath: the index of the row being edited
   */
  public func tableView(
    _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    if editingStyle == .delete {
      let obj = object(at: indexPath)
      delegate.delete(obj, at: indexPath)
    }
  }

  // MARK: - NSFetchedResultsControllerDelegate

  /**
   Notification from NSFetchedResultsController that it is is going to make changes that affect the view

   - parameter controller: the controller performing the work
   */
  public func controllerWillChangeContent(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>
  ) {
    os_log(.info, log: log, "controllerWillChangeContent - beginUpdates")
    tableView.beginUpdates()
  }

  /**
   Notification from NSFetchedResultsController about a change at a given index.

   - parameter controller: the controller performing the work
   - parameter anObject: the object being affected
   - parameter indexPath: the index of the object being affected
   - parameter type: the type of change being performed
   - parameter newIndexPath: the new index of the object after the operation (optional)
   */
  public func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?
  ) {
    switch type {
    case .insert: insertRow(newIndexPath)
    case .update: updateRow(indexPath)
    case .move: moveRow(indexPath, newIndexPath)
    case .delete: deleteRow(indexPath)
    @unknown default: fatalError("unexpected NSFetchedResultsChangeType value - \(type) ")
    }
  }

  /**
   Notification from NSFetchedResultsController that all changes are done. Notify the delegate that the view was
   changed.

   - parameter controller: the controller that performed the work
   */
  public func controllerDidChangeContent(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>
  ) {
    os_log(.info, log: log, "controllerDidChangeContent - endUpdates")
    tableView.endUpdates()
    delegate.updated()
  }
}

extension TableViewDataSource {
  private func insertRow(_ indexPath: IndexPath?) {
    guard let indexPath = indexPath else { fatalError("indexPath should not be nil") }
    os_log(.info, log: log, "insertRow - %d", indexPath.row)
    tableView.insertRows(at: [indexPath], with: .fade)
  }

  private func updateRow(_ indexPath: IndexPath?) {
    guard let indexPath = indexPath else { fatalError("indexPath should not be nil") }
    os_log(.info, log: log, "updateRow - %d", indexPath.row)
    guard let cell = tableView.cellForRow(at: indexPath) as? Cell else { return }
    delegate?.configure(cell, for: object(at: indexPath))
  }

  private func moveRow(_ old: IndexPath?, _ new: IndexPath?) {
    guard let indexPath = old else { fatalError("old should not be nil") }
    guard let newIndexPath = new else { fatalError("new should not be nil") }
    os_log(.info, log: log, "moveRow - %d %d", indexPath.row, newIndexPath.row)
    tableView.deleteRows(at: [indexPath], with: .fade)
    tableView.insertRows(at: [newIndexPath], with: .fade)
  }

  private func deleteRow(_ indexPath: IndexPath?) {
    guard let indexPath = indexPath else { fatalError("indexPath should not be nil") }
    os_log(.info, log: log, "deleteRow")
    tableView.deleteRows(at: [indexPath], with: .fade)
  }
}
