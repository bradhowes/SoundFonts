// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Amount.hpp"
#include "Render/Range.hpp"

using namespace SF2::Render;

@interface RangeTests : XCTestCase
@end

@implementation RangeTests

- (void)testRange {
    Range range(0, 50);
    XCTAssertEqual(0, range.low());
    XCTAssertEqual(50, range.high());

    XCTAssertTrue(range.contains(0));
    XCTAssertTrue(range.contains(30));
    XCTAssertTrue(range.contains(50));

    XCTAssertFalse(range.contains(-1));
    XCTAssertFalse(range.contains(51));
}

@end
