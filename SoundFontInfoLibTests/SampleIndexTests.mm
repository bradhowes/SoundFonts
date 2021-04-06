// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>
#import <XCTest/XCTest.h>
#include "Entity/SampleHeader.hpp"
#include "Render/SampleIndex.hpp"

using namespace SF2::Entity;
using namespace SF2::Render;

@interface SampleIndexTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation SampleIndexTests

static SampleHeader header(0, 6, 2, 5, 100, 69, 0);

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)tearDown {
}

- (void)testConstruction {
    XCTAssertEqual(0.0, SampleIndex(header, 1.1).pos());
}

- (void)testIncrement {
    auto index = SampleIndex(header, 1.1);
    index.increment(true);
    XCTAssertEqual(1.1, index.pos());
    index.increment(true);
    XCTAssertEqual(2.2, index.pos());
}

- (void)testLooping {
    auto epsilon = 0.0000001;
    auto index = SampleIndex(header, 1.1);
    index.increment(true);
    XCTAssertEqualWithAccuracy(1.1, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(2.2, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(3.3, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(4.4, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(2.5, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(3.6, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(4.7, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(2.8, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(3.9, index.pos(), epsilon);
}

- (void)testEndLooping {
    auto epsilon = 0.0000001;
    auto index = SampleIndex(header, 1.1);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    XCTAssertEqualWithAccuracy(3.6, index.pos(), epsilon);
    index.increment(true);
    XCTAssertEqualWithAccuracy(4.7, index.pos(), epsilon);
    index.increment(false);
    XCTAssertEqualWithAccuracy(5.8, index.pos(), epsilon);
    index.increment(false);
    XCTAssertEqualWithAccuracy(6.9, index.pos(), epsilon);
}

- (void)testFinished {
    auto epsilon = 0.0000001;
    auto index = SampleIndex(header, 1.1);
    index.increment(false);
    XCTAssertEqualWithAccuracy(1.1, index.pos(), epsilon);
    index.increment(false);
    XCTAssertEqualWithAccuracy(2.2, index.pos(), epsilon);
    index.increment(false);
    XCTAssertEqualWithAccuracy(3.3, index.pos(), epsilon);
    index.increment(false);
    XCTAssertEqualWithAccuracy(4.4, index.pos(), epsilon);
    index.increment(false);
    XCTAssertEqualWithAccuracy(5.5, index.pos(), epsilon);
    XCTAssertFalse(index.finished());
    index.increment(false);
    XCTAssertEqualWithAccuracy(6.6, index.pos(), epsilon);
    XCTAssertTrue(index.finished());
}

@end
