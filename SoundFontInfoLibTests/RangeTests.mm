// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Amount.hpp"
#include "Render/Range.hpp"

using namespace SF2::Render;
using namespace SF2::Entity::Generator;

@interface RangeTests : XCTestCase
@end

@implementation RangeTests

- (void)testRange {
    Range<int> range(0, 50);
    XCTAssertEqual(0, range.low());
    XCTAssertEqual(50, range.high());

    XCTAssertTrue(range.contains(0));
    XCTAssertTrue(range.contains(30));
    XCTAssertTrue(range.contains(50));

    XCTAssertFalse(range.contains(-1));
    XCTAssertFalse(range.contains(51));
}

- (void)testRangeConversion {
    Range<uint8_t> range(Amount(0x3200));
    XCTAssertEqual(0, range.low());
    XCTAssertEqual(50, range.high());

    range = Range<uint8_t>(Amount(0x7F7F));
    XCTAssertEqual(127, range.low());
    XCTAssertEqual(127, range.high());

    range = Range<uint8_t>(Amount(0x00FF));
    XCTAssertEqual(255, range.low());
    XCTAssertEqual(0, range.high());
}

@end
