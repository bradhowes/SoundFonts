// Copyright © 2019 Brad Howes. All rights reserved.

import CoreData

/**
 Useful extensions to NSManagedObjectContext
 */
public extension NSManagedObjectContext {

    /**
     Create a new managed object of type A and insert it into the managed context.

     - returns: new managed object of type A
     */
    @discardableResult func insertObject<A>(_ config: ((A) -> A) = {$0}) -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else {
            fatalError("Wrong object type")
        }
        return config(obj)
    }

    func saveChanges() throws {
        if hasChanges { try save() }
    }

    func saveChangesAsync() {
        if hasChanges {
            perform { self.saveOrRollback() }
        }
    }

    /**
     Attempt to save the context to storage, rollingback if the save fails.

     - returns: true if saved
     */
    @discardableResult func saveOrRollback() -> Bool {
        do {
            try saveChanges()
            return true
        }
        catch {
            rollback()
            return false
        }
    }

    /**
     Execute a block asynchronously and then try to save the context.

     - parameter block: block to execute
     */
    func performChangesAndSaveAsync(block: @escaping () -> Void) {
        perform {
            block()
            self.saveOrRollback()
        }
    }
}

public extension NSManagedObjectContext {

    private var NC: NotificationCenter { NotificationCenter.default }

    /**
     Regiser to receive notifications when this context has been saved.

     - parameter block: the block to execute after a save. It will receive a ContextNotification that
       identifies the objects that were added, updated, and/or deleted since the last save event.
     - returns: reference to the observation
     */
    func notifyOnSave<T: NSManagedObject>(_ block: @escaping (ContextNotification<T>) -> Void) -> NSObjectProtocol {
        return NC.addObserver(forName: .NSManagedObjectContextDidSave, object: self, queue: nil) {
            block(ContextNotification<T>(notification: $0))
        }
    }

    /**
     Regiser to receive notifications when this context is processing changes but before they have been saved.

     - parameter block: the block to execute after a save. It will receive a ContextNotification that
     identifies the objects that were added, updated, and/or deleted since the last save event.
     - returns: reference to the observation
     */
    func notifyOnChanges<T: NSManagedObject>(_ block: @escaping (ContextNotification<T>) -> Void) -> NSObjectProtocol {
        return NC.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: self, queue: nil) {
            block(ContextNotification<T>(notification: $0))
        }
    }
}

private let singleObjectCacheKey = "SingleObjectCache"
private typealias SingleObjectCache = [String: NSManagedObject]

public extension NSManagedObjectContext {

    func set(_ object: NSManagedObject?, forSingleObjectCacheKey key: String) {
        var cache = userInfo[singleObjectCacheKey] as? SingleObjectCache ?? [:]
        cache[key] = object
        userInfo[singleObjectCacheKey] = cache
    }

    func object<T>(forSingleObjectCacheKey key: String) -> T? where T: NSManagedObject {
        guard let cache = userInfo[singleObjectCacheKey] as? SingleObjectCache else { return nil }
        return cache[key] as? T
    }
}
