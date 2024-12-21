// Copyright © 2019 Brad Howes. All rights reserved.

import CoreData

/// A protocol for objects that are managed by a CoreData NSManagedObjectContext
public protocol Managed: NSFetchRequestResult {

  /// The name of the model that defines instances of the managed type
  static var entityName: String { get }

  /// Ordering for instances fetched from the persistent container. By default there is no ordering.
  static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension Managed {

  public typealias FetchRequest = NSFetchRequest<Self>
  public typealias FetchConfigurator = (FetchRequest) -> Void
  public typealias Initializer = (Self) -> Void

  /// Default sort definition
  public static var defaultSortDescriptors: [NSSortDescriptor] { [] }

  /// Obtain generic fetch request
  public static var typedFetchRequest: FetchRequest { FetchRequest(entityName: entityName) }

  /// Obtain a fetch request that is sorted according to defaultSortDescriptors
  public static var sortedFetchRequest: FetchRequest {
    let request = typedFetchRequest
    request.sortDescriptors = defaultSortDescriptors
    return request
  }

  /// Count the number of items returned by a given fetch request
  public static func count(in context: NSManagedObjectContext, request: FetchRequest) -> Int {
    (try? context.count(for: request)) ?? 0
  }
}

extension Managed where Self: NSManagedObject {

  public static var entityName: String { entity().name ?? "!!!" }

  /**
   Create a fetch request and execute it.

   - parameter context: the context where the managed objects live
   - parameter request: what to request
   - returns: array of managed objects
   */
  public static func fetch(in context: NSManagedObjectContext, request: FetchRequest) -> [Self] {
    guard let result = try? context.fetch(request) else { fatalError() }
    return result
  }

  /**
   Find or create a managed object

   - parameter context: the context where the managed objects live
   - parameter request: what to request
   - parameter block: code to run to initialize an object
   - returns: found/created managed object
   */
  public static func findOrCreate(in context: NSManagedObjectContext, request: FetchRequest,
                                  initializer: Initializer) -> Self {
    guard let object = findOrFetch(in: context, request: request) else {
      let newObject: Self = context.insertObject()
      initializer(newObject)
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
  public static func findOrFetch(in context: NSManagedObjectContext, request: FetchRequest) -> Self? {
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
  public static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate?) -> Self? {
    for object in context.registeredObjects where !object.isFault {
      guard let result = object as? Self, predicate?.evaluate(with: result) ?? true else {
        continue
      }
      return result
    }
    return nil
  }

  /// Delete the managed object
  public func delete() {
    managedObjectContext?.delete(self)
  }

  /// Obtain the ManagedAppState singleton from the context associated with this entity
  public var appState: ManagedAppState {
    guard let context = managedObjectContext else {
      fatalError("attempt to use nil NSManagedObjectContext")
    }
    return ManagedAppState.get(context: context)
  }
}
