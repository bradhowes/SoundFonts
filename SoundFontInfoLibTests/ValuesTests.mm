// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Render/Voice/Values.hpp"

using namespace SF2::Render::Voice::Value;

@interface ValuesTests : XCTestCase
@end

@implementation ValuesTests

- (void)testOffset {
    Offset a{123};
    XCTAssertEqual(123, a.value());
    Offset b{456};
    XCTAssertEqual(123 + 456, (a + b).value());
}

- (void)testCoarseOffset {
    CoarseOffset a{123};
    XCTAssertEqual(123 * 65536, a.value());
    Offset b{456};
    XCTAssertEqual(123 * 65536 + 456, (a + b).value());
}

- (void)testPercentage {
    Percentage a{1234};
    XCTAssertEqualWithAccuracy(1.234, a.value(), 0.000001);
    Percentage b{-1234};
    XCTAssertEqualWithAccuracy(-1.234, b.value(), 0.000001);
}

- (void)testTimeCents {
    TimeCents a{-7973};
    XCTAssertEqual(-7973, a.value());
    XCTAssertEqualWithAccuracy(0.01, a.asSeconds(), 0.00001);

    TimeCents b{7973};
    XCTAssertEqual(7973, b.value());
    XCTAssertEqualWithAccuracy(1.0, (a + b).asSeconds(), 0.00001);
}

- (void)testFrequencyCents {
    FrequencyCents a{0};
    XCTAssertEqual(0, a.value());
    XCTAssertEqualWithAccuracy(8.17579891564, a.asFrequency(), 0.00001);

    FrequencyCents b{1500};
    XCTAssertEqualWithAccuracy(19.4454364826, b.asFrequency(), 0.000001);

    FrequencyCents c{13500};
    XCTAssertEqualWithAccuracy(19912.1269582, c.asFrequency(), 0.000001);

    FrequencyCents d{-16000};
    XCTAssertEqualWithAccuracy(0.00079213084713, d.asFrequency(), 0.000001);

    FrequencyCents e{4500};
    XCTAssertEqualWithAccuracy(110.0, e.asFrequency(), 0.000001);

}

@end
