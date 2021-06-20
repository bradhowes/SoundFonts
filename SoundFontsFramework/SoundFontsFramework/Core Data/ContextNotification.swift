// Copyright © 2020 Brad Howes. All rights reserved.

import CoreData
import Foundation

/// Wrapper around a Notification from an NSManagedObjectContext that offers type-checked access to various
/// attributes from the Notification payload.
///
/// NOTE: as Apple's documentation states:
///
///   You can only use the managed objects in this notification on the same thread on which it was posted.
public struct ContextNotification<T> where T: NSManagedObject {

  private let notification: Notification

  /// Obtain an iterator over the objects that have been inserted.
  public var insertedObjects: AnyIterator<T> { iterator(forKey: NSInsertedObjectsKey) }

  /// Obtain an iterator over the objects that have been updated.
  public var updatedObjects: AnyIterator<T> { iterator(forKey: NSUpdatedObjectsKey) }

  /// Obtain an iterator over the objects that have been deleted.
  public var deletedObjects: AnyIterator<T> { iterator(forKey: NSDeletedObjectsKey) }

  /// Get the managed object context from the notification payload.
  public var managedObjectContext: NSManagedObjectContext {
    guard let context = notification.object as? NSManagedObjectContext else { fatalError() }
    return context
  }

  /**
   Create wrapper for the given notification. The notification's name must be .NSManagedObjectContextDidSave.

   - parameter notification: the object to wrap
   */
  public init(notification: Notification) {
    guard
      notification.name == .NSManagedObjectContextDidSave
        || notification.name == .NSManagedObjectContextObjectsDidChange
    else {
      fatalError("incorrect notification")
    }
    self.notification = notification
  }

  /// Get an iterator to a collection of managed objects from the notification payload.
  private func iterator(forKey key: String) -> AnyIterator<T> {
    guard let collection = notification.userInfo?[key] as? NSSet else { return AnyIterator { nil } }
    var innerIterator = collection.makeIterator()
    return AnyIterator { return innerIterator.next() as? T }
  }
}
