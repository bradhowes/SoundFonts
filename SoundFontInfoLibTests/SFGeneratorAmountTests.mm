// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/GeneratorAmount.hpp"
#include "Render/Zone.hpp"

using namespace SF2;

@interface SFGeneratorAmountTests : XCTestCase
@end

@implementation SFGeneratorAmountTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testRange {
    {
        Entity::GeneratorAmount amt(0);
        XCTAssertEqual(0, amt.low());
        XCTAssertEqual(0, amt.high());
    }
    {
        Entity::GeneratorAmount amt(0x7F7F);
        XCTAssertEqual(127, amt.low());
        XCTAssertEqual(127, amt.high());
    }
    {
        Entity::GeneratorAmount amt(0x7F00);
        XCTAssertEqual(0, amt.low());
        XCTAssertEqual(127, amt.high());
    }
}

- (void)testRangeConversion {
    Render::Zone::Range range(Entity::GeneratorAmount(0x3200));
    XCTAssertEqual(0, range.low());
    XCTAssertEqual(50, range.high());
}

@end
