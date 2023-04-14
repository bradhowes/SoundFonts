import CoreData
import Foundation

/// Light-weight wrapper around an NSOrderedSet that provides typed and indexed access to the contents.
struct EntityCollection<T>: RandomAccessCollection where T: NSManagedObject {

  private let source: NSOrderedSet

  var count: Int { source.count }
  var startIndex: Int { 0 }
  var endIndex: Int { source.count }

  init(_ source: NSOrderedSet) { self.source = source }

  subscript(index: Int) -> T {
    guard let value = source[index] as? T else { fatalError() }
    return value
  }
}
