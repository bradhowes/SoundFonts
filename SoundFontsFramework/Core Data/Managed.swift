// Copyright © 2019 Brad Howes. All rights reserved.

import CoreData

/**
 A protocol for objects that are managed by a CoreData NSManagedObjectContext
 */
public protocol Managed: class, NSFetchRequestResult {

    /// The name of the model that defines instances of the managed type
    static var entityName: String { get }

    /// Ordering for instances fetched from the persistent container. By default there is no ordering.
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

// MARK: - default implementation

public extension Managed {

    /// Default sort definition
    static var defaultSortDescriptors: [NSSortDescriptor] { [] }

    /// Obtain a fetch request that is sorted according to defaultSortDescriptors
    static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        return request
    }

    /**
     Obtain a fetch request that is sorted according to a given predicate

     - parameter predicate: defines the sorting order
     - returns: new NSFetchRequest
     */
    static func sortedFetchRequest(with predicate: NSPredicate) -> NSFetchRequest<Self> {
        let request = sortedFetchRequest
        request.predicate = predicate
        return request
    }
}

// MARK: Specialization when Managed derives from NSManagedObject

public extension Managed where Self: NSManagedObject {

    static var entityName: String { entity().name! }

    /**
     Create a fetch request and execute it.

     - parameter context: the context where the managed objects live
     - paramater configurationBlock: a block to run to configure the fetch request before executing it
     - returns: array of managed objects
     */
    static func fetch(in context: NSManagedObjectContext,
                      configurationBlock: (NSFetchRequest<Self>) -> Void = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: entityName)
        configurationBlock(request)
        return try! context.fetch(request)
    }

    /**
     Find or create a managed object

     - parameter context: the context where the managed objects live
     - parameter predicate: the match definition
     - parameter configure: block to run with a new managed object
     - returns: found/created managed object
     */
    static func findOrCreate(in context: NSManagedObjectContext, matching predicate: NSPredicate,
                             configure: (Self) -> Void) -> Self {
        guard let object = findOrFetch(in: context, matching: predicate) else {
            let newObject: Self = context.insertObject()
            configure(newObject)
            return newObject
        }
        return object
    }

    /**
     Create a fetch request that returns the first item that matches a given predicate.

     - parameter context: the context where the managed objects live
     - parameter predicate: the match definition
     - returns: optional found object
     */
    static func findOrFetch(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        guard let object = materializedObject(in: context, matching: predicate) else {
            return fetch(in: context) { request in
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                }.first
        }
        return object
    }

    /**
     Obtain the first registered object in the context that matches a given predicate.

     - parameter context: the context where the managed objects live
     - parameter predicate: the match definition
     - returns: optional found object
     */
    static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self, predicate.evaluate(with: result) else { continue }
            return result
        }
        return nil
    }
}
