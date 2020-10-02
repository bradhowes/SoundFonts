// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest
import SoundFontsFramework

class FilteredOrderedCollectionTests: XCTestCase {

    func testEmptyCollection() {
        let collection = FilteredOrderedCollection(source: [], filter: {($0 % 2) == 1})
        XCTAssertTrue(collection.isEmpty)
        XCTAssertEqual(0, collection.count)
    }

    func testPODCollection() {
        let collection = FilteredOrderedCollection(source: [1, 2, 3, 4, 5, 6, 7, 8], filter: {($0 % 2) == 1})
        XCTAssertFalse(collection.isEmpty)
        XCTAssertEqual(4, collection.count)
        XCTAssertEqual(1, collection.find(3))
        XCTAssertNil(collection.find(4))
        XCTAssertEqual([1, 3, 5, 7], collection.map { $0 })
    }

    class Entry: Comparable {
        static func < (lhs: FilteredOrderedCollectionTests.Entry, rhs: FilteredOrderedCollectionTests.Entry) -> Bool { lhs.value < rhs.value }
        static func == (lhs: FilteredOrderedCollectionTests.Entry, rhs: FilteredOrderedCollectionTests.Entry) -> Bool { lhs === rhs }
        let value: Int
        init(_ value: Int) { self.value = value }
    }

    func testObjectCollection() {
        let source = [Entry(1), Entry(2), Entry(3), Entry(4), Entry(5), Entry(6), Entry(7), Entry(8)]
        let collection = FilteredOrderedCollection(source: source, filter: {($0.value % 2) == 1})
        XCTAssertFalse(collection.isEmpty)
        XCTAssertEqual(4, collection.count)
        XCTAssertEqual(1, collection.find(source[2]))
        XCTAssertNil(collection.find(source[3]))
        XCTAssertEqual([1, 3, 5, 7], collection.map { $0.value })
    }
}
