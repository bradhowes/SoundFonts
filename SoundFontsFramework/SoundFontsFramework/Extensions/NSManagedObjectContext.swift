// Copyright © 2019 Brad Howes. All rights reserved.

import CoreData

/// Useful extensions to NSManagedObjectContext
extension NSManagedObjectContext {

  /**
   Create a new managed object of type A and insert it into the managed context.

   - returns: new managed object of type A
   */
  @discardableResult public func insertObject<A>(_ config: ((A) -> A) = { $0 }) -> A
  where A: Managed {
    guard
      let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A
    else {
      fatalError("Wrong object type")
    }
    return config(obj)
  }

  /// Save changes made to entities managed by this context
  public func saveChanges() throws { if hasChanges { try save() } }

  /// Save changes made to entities managed by this context without blocking.
  public func saveChangesAsync() {
    if hasChanges {
      perform { self.saveOrRollback() }
    }
  }

  /**
   Attempt to save the context to storage, rolling back if the save fails.

   - returns: true if saved
   */
  @discardableResult public func saveOrRollback() -> Bool {
    do {
      try saveChanges()
      return true
    } catch {
      rollback()
      return false
    }
  }

  /**
   Execute a block asynchronously and then try to save the context.

   - parameter block: block to execute
   */
  public func performChangesAndSaveAsync(block: @escaping () -> Void) {
    perform {
      block()
      self.saveOrRollback()
    }
  }
}

public extension NSManagedObjectContext {

  private var NC: NotificationCenter { NotificationCenter.default }

  /**
   Register to receive notifications when this context has been saved.

   - parameter block: the block to execute after a save. It will receive a ContextNotification that
   identifies the objects that were added, updated, and/or deleted since the last save event.
   - returns: reference to the observation
   */
  func notifyOnSave<T: NSManagedObject>(_ block: @escaping (ContextNotification<T>) -> Void) -> NSObjectProtocol {
    NC.addObserver(forName: .NSManagedObjectContextDidSave, object: self, queue: nil) {
      block(ContextNotification<T>(notification: $0))
    }
  }

  /**
   Register to receive notifications when this context is processing changes but before they have been saved.

   - parameter block: the block to execute after a save. It will receive a ContextNotification that
   identifies the objects that were added, updated, and/or deleted since the last save event.
   - returns: reference to the observation
   */
  func notifyOnChanges<T: NSManagedObject>(_ block: @escaping (ContextNotification<T>) -> Void) -> NSObjectProtocol {
    NC.addObserver(
      forName: .NSManagedObjectContextObjectsDidChange, object: self, queue: nil
    ) {
      block(ContextNotification<T>(notification: $0))
    }
  }
}

private let singleObjectCacheKey = "SingleObjectCache"
private typealias SingleObjectCache = [String: NSManagedObject]

public extension NSManagedObjectContext {

  /**
   Set a managed object in a cache.

   - parameter object: the value to cache
   - parameter key: the key to store under
   */
  func set(_ object: NSManagedObject?, forSingleObjectCacheKey key: String) {
    var cache = userInfo[singleObjectCacheKey] as? SingleObjectCache ?? [:]
    cache[key] = object
    userInfo[singleObjectCacheKey] = cache
  }

  /**
   Obtain an object from the cache

   - parameter key: the value to look for
   - returns: object found in cache or nil
   */
  func object<T>(forSingleObjectCacheKey key: String) -> T? where T: NSManagedObject {
    guard let cache = userInfo[singleObjectCacheKey] as? SingleObjectCache else { return nil }
    return cache[key] as? T
  }
}
