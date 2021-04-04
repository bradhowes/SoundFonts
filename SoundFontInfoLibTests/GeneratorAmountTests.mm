// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Amount.hpp"
#include "Render/Zone.hpp"

using namespace SF2::Entity::Generator;
using namespace SF2::Render;

@interface GeneratorAmountTests : XCTestCase
@end

@implementation GeneratorAmountTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testRange {
    {
        Amount amt(0);
        XCTAssertEqual(0, amt.low());
        XCTAssertEqual(0, amt.high());
    }
    {
        Amount amt(0x7F7F);
        XCTAssertEqual(127, amt.low());
        XCTAssertEqual(127, amt.high());
    }
    {
        Amount amt(0x7F00);
        XCTAssertEqual(0, amt.low());
        XCTAssertEqual(127, amt.high());
    }
}

- (void)testRangeConversion {
    Zone::Range range(Amount(0x3200));
    XCTAssertEqual(0, range.low());
    XCTAssertEqual(50, range.high());
}

@end
