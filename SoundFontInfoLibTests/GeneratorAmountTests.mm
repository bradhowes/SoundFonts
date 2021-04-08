// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Amount.hpp"
#include "Render/Range.hpp"

using namespace SF2::Entity::Generator;
using namespace SF2::Render;

@interface GeneratorAmountTests : XCTestCase
@end

@implementation GeneratorAmountTests

- (void)testRange {
    Amount amount(0);
    XCTAssertEqual(0, amount.low());
    XCTAssertEqual(0, amount.high());

    amount = Amount(0x7F7F);
    XCTAssertEqual(127, amount.low());
    XCTAssertEqual(127, amount.high());

    amount = Amount(0x7F00);
    XCTAssertEqual(0, amount.low());
    XCTAssertEqual(127, amount.high());

    amount = Amount(0xFF80);
    XCTAssertEqual(128, amount.low());
    XCTAssertEqual(255, amount.high());
}

- (void)testRangeConversion {
    Range range(Amount(0x3200));
    XCTAssertEqual(0, range.low());
    XCTAssertEqual(50, range.high());

    range = Range(Amount(0x7F7F));
    XCTAssertEqual(127, range.low());
    XCTAssertEqual(127, range.high());

    range = Range(Amount(0x00FF));
    XCTAssertEqual(255, range.low());
    XCTAssertEqual(0, range.high());
}

@end
