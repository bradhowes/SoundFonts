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
    auto index = SampleIndex(header, 1.1);
    XCTAssertEqual(0, index.index());
    XCTAssertEqual(0, index.partial());
}

- (void)testIncrement {
    auto index = SampleIndex(header, 1.3);
    index.increment(true);
    XCTAssertEqual(1, index.index());
    index.increment(true);
    XCTAssertEqual(2, index.index());
    XCTAssertEqualWithAccuracy(0.6, index.partial(), 0.000001);
}

- (void)testLooping {
    auto index = SampleIndex(header, 1.3);
    index.increment(true);
    XCTAssertEqual(1, index.index());
    index.increment(true);
    XCTAssertEqual(2, index.index());
    index.increment(true);
    XCTAssertEqual(3, index.index());
    index.increment(true);
    XCTAssertEqual(2, index.index());
    index.increment(true);
    XCTAssertEqual(3, index.index());
    index.increment(true);
    XCTAssertEqual(4, index.index());
    index.increment(true);
    XCTAssertEqual(3, index.index());
    index.increment(true);
    XCTAssertEqual(4, index.index());
    index.increment(true);
    XCTAssertEqual(2, index.index());
}

- (void)testEndLooping {
    auto index = SampleIndex(header, 1.3);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    index.increment(true);
    XCTAssertEqual(3, index.index());
    index.increment(true);
    XCTAssertEqual(4, index.index());
    index.increment(false);
    XCTAssertEqual(6, index.index());
    index.increment(false);
    XCTAssertEqual(6, index.index());
}

- (void)testFinished {
    auto index = SampleIndex(header, 1.3);
    index.increment(false);
    XCTAssertEqual(1, index.index());
    index.increment(false);
    XCTAssertEqual(2, index.index());
    index.increment(false);
    XCTAssertEqual(3, index.index());
    index.increment(false);
    XCTAssertEqual(5, index.index());
    XCTAssertFalse(index.finished());
    index.increment(false);
    XCTAssertEqual(6, index.index());
    XCTAssertTrue(index.finished());
    index.increment(false);
    XCTAssertEqual(6, index.index());
}

@end
