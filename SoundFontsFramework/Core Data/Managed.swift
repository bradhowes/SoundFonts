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

public extension Managed {

    typealias FetchRequest = NSFetchRequest<Self>
    typealias FetchConfigurator = (FetchRequest) -> Void
    typealias Initializer = (Self) -> Void

    /// Default sort definition
    static var defaultSortDescriptors: [NSSortDescriptor] { [] }

    /// Obtain generic fetch request
    static var typedFetchRequest: FetchRequest { FetchRequest(entityName: entityName) }

    /// Obtain a fetch request that is sorted according to defaultSortDescriptors
    static var sortedFetchRequest: FetchRequest {
        let request = typedFetchRequest
        request.sortDescriptors = defaultSortDescriptors
        return request
    }

    /// Count the number of items returned by a given fetch request
    static func count(in context: NSManagedObjectContext, request: FetchRequest) -> Int {
        (try? context.count(for: request)) ?? 0
    }
}

public extension Managed where Self: NSManagedObject {

    static var entityName: String { entity().name! }

    /**
     Create a fetch request and execute it.

     - parameter context: the context where the managed objects live
     - paramater request: what to request
     - returns: array of managed objects
     */
    static func fetch(in context: NSManagedObjectContext, request: FetchRequest) -> [Self] {
        guard let result = try? context.fetch(request) else { fatalError() }
        return result
    }

    /**
     Find or create a managed object

     - parameter context: the context where the managed objects live
     - paramater request: what to request
     - returns: found/created managed object
     */
    static func findOrCreate(in context: NSManagedObjectContext, request: FetchRequest, initer: Initializer) -> Self {
        guard let object = findOrFetch(in: context, request: request) else {
            let newObject: Self = context.insertObject()
            initer(newObject)
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
    static func findOrFetch(in context: NSManagedObjectContext, request: FetchRequest) -> Self? {
        guard let object = materializedObject(in: context, matching: request.predicate) else {
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            return fetch(in: context, request: request).first
        }
        return object
    }

    /**
     Obtain the first registered object in the context that matches a given predicate.

     - parameter context: the context where the managed objects live
     - parameter predicate: the match definition
     - returns: optional found object
     */
    static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate?) -> Self? {
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self, predicate?.evaluate(with: result) ?? true else { continue }
            return result
        }
        return nil
    }

    func delete() {
        managedObjectContext?.delete(self)
    }
}
