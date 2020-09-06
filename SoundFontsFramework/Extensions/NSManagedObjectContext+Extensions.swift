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
    func insertObject<A>() -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else {
            fatalError("Wrong object type")
        }
        return obj
    }

    /**
     Attempt to save the context to storage, rollingback if the save fails.

     - returns: true if saved
     */
    @discardableResult func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        }
        catch {
            rollback()
            return false
        }
    }

    /**
     Execute a block and then try to save the context.

     - parameter block: block to execute
     */
    func performChanges(block: @escaping () -> Void) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }
}

public extension NSManagedObjectContext {

    /**
     Receive notifications when the context is saved.

     - parameter handler: the block to execute after a save. It will receive a ContextDidSaveNotification that
       identifies the objects that were added, updated, and/or deleted since the last save event.
     - returns: reference to the observation
     */
    func addContextDidSaveNotification<T: NSManagedObject>(_ handler: @escaping (ContextDidSaveNotification<T>) -> Void)
        -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: self,
                                                      queue: nil) { notification in
            let wrapped = ContextDidSaveNotification<T>(notification: notification)
            handler(wrapped)
        }
    }
}
