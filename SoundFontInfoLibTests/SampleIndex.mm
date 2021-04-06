// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>
#import <XCTest/XCTest.h>
#include "Render/SampleIndex.hpp"

using namespace SF2::Render;

@interface SampleIndexTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation SampleIndexTests

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)tearDown {
}

- (void)testConstruction {
    auto a = SampleIndex(1.0);
    XCTAssertEqual(1, a.whole());
    XCTAssertEqual(0.0, a.partial());
    XCTAssertEqualWithAccuracy(1.0, a.value(), _epsilon);

    a = SampleIndex(1.2345);
    XCTAssertEqual(1, a.whole());
    XCTAssertEqual(1007169830, a.partial());
    XCTAssertEqualWithAccuracy(1.2345, a.value(), _epsilon);
}

- (void)testIncrement {
    auto a = SampleIndex(1.2345);
    ++a;
    XCTAssertEqual(2, a.whole());
    XCTAssertEqual(1007169830, a.partial());
    XCTAssertEqualWithAccuracy(2.2345, a.value(), _epsilon);
}

- (void)testDecrement {
    auto a = SampleIndex(1.2345);
    --a;
    XCTAssertEqual(0, a.whole());
    XCTAssertEqual(1007169830, a.partial());
    XCTAssertEqualWithAccuracy(0.2345, a.value(), _epsilon);
}

- (void)testAdd {
    auto a = SampleIndex(1.2345);
    auto b = SampleIndex(2.8123);
    a += b;
    XCTAssertEqual(4, a.whole());
    XCTAssertEqual(201004467, a.partial());
    XCTAssertEqualWithAccuracy(4.0468, a.value(), _epsilon);
}

- (void)testSubtract {
    auto a = SampleIndex(1.2345);
    auto b = SampleIndex(2.8123);
    b -= a;
    XCTAssertEqual(1, b.whole());
    XCTAssertEqual(2481632103, b.partial());
    XCTAssertEqualWithAccuracy(2.8123 - 1.2345, b.value(), _epsilon);

    a -= a;
    XCTAssertEqual(0, a.whole());
    XCTAssertEqual(0, a.partial());
    XCTAssertEqualWithAccuracy(0.0, a.value(), _epsilon);
}

@end
