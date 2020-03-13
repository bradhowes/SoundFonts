// Copyright © 2020 Brad Howes. All rights reserved.

import XCTest

class RandomAccessCollection_Extensions: XCTestCase {

    func testNilMinMax() {
        let collection = [Int]()
        let minMax = collection.minMax()
        XCTAssertNil(minMax)
    }

    func testMinMax() {
        let collection = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        guard let minMax = collection.minMax() else {
            fatalError()
        }

        XCTAssertEqual(1, minMax.min)
        XCTAssertEqual(9, minMax.max)
    }

    func testContains() {
        let sorted = [1, 2, 3, 5, 6, 7]
        XCTAssertTrue(sorted.contains(5))
        XCTAssertTrue(sorted.contains(3))
        XCTAssertFalse(sorted.contains(4))
    }

//    func testPerformanceExample() {
//        self.measure {
//        }
//    }
}
