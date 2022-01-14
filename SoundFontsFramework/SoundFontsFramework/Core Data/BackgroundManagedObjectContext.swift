import CoreData

public final class BackgroundManagedObjectContext {

  private var context: NSManagedObjectContext

  public init(_ context: NSManagedObjectContext) {
    self.context = context
  }

  deinit {
    context.performAndWait {}
  }
}

extension BackgroundManagedObjectContext: Tasking {

  public convenience init(
    _ container: NSPersistentContainer, _ configure: (NSManagedObjectContext) -> Void
  ) {
    let context = container.newBackgroundContext()
    configure(context)
    self.init(context)
  }

  public func performTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
    context.perform { [weak self] in self.map { block($0.context) } }
  }

  public func write(
    errorBlock: @escaping (Error?) -> Void,
    _ taskBlock: @escaping (NSManagedObjectContext) throws -> Void
  ) {
    performTask { context in
      context.reset()
      defer { context.reset() }

      var resultError: Error?
      do {
        try taskBlock(context)
        try context.saveChanges()
      } catch {
        resultError = error
      }

      Self.onMain { errorBlock(resultError) }
    }
  }
}
