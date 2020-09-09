import Foundation

public struct EntityCollection<T>: RandomAccessCollection where T: Managed {

    private let source: NSOrderedSet

    public var startIndex: Int { return 0 }
    public var endIndex: Int { return source.count }

    public var count: Int { source.count }

    public init(_ source: NSOrderedSet) { self.source = source }

    public subscript(index: Int) -> T { source[index] as! T }
}
