// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation

public struct FilteredOrderedCollection<Element> where Element: Comparable {

    private let filtered: [Element]

    public init() { self.filtered = [] }

    public init(source: [Element], filter: (Element) -> Bool) {
        self.filtered = source.filter(filter)
    }

    public func find(_ item: Element) -> Int? {
        let index = filtered.search(for: item) { $0 < $1 }
        return index == endIndex ? nil : index
    }
}

extension FilteredOrderedCollection: Collection {

    public typealias Index = Int
    public typealias Element = Element

    public var startIndex: Index { filtered.startIndex }
    public var endIndex: Index { filtered.endIndex }

    public subscript(index: Index) -> Element { filtered[index] }
    public func index(after index: Index) -> Index { filtered.index(after: index) }
}
