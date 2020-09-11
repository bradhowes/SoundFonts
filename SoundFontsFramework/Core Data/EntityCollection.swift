import Foundation
import CoreData

/**
 Light-weight wrapper around an NSOrderedSet that provides typed and indexed access to the contents.
 */
public struct EntityCollection<T>: RandomAccessCollection where T: NSManagedObject {

    private let source: NSOrderedSet

    public var count: Int { source.count }
    public var startIndex: Int { 0 }
    public var endIndex: Int { source.count }

    public init(_ source: NSOrderedSet) { self.source = source }

    public subscript(index: Int) -> T { source[index] as! T }
}
