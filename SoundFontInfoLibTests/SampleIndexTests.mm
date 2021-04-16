// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>
#import <XCTest/XCTest.h>
#import "Entity/SampleHeader.hpp"
#import "Render/Sample/BufferIndex.hpp"
#import "Render/Voice/State.hpp"

using namespace SF2::Render::Sample;
using namespace SF2::Render::Voice;

@interface SampleIndexTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation SampleIndexTests

static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);
static Bounds bounds{header, State()};

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)tearDown {
}

- (void)testConstruction {
    auto index = BufferIndex();
    XCTAssertEqual(0, index.index());
    XCTAssertEqual(0, index.partial());
}

- (void)testIncrement {
    auto index = BufferIndex();
    index.setIncrement(1.3);
    index.increment(bounds, true);
    XCTAssertEqual(1, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(2, index.index());
    XCTAssertEqualWithAccuracy(0.6, index.partial(), 0.000001);
}

- (void)testLooping {
    auto index = BufferIndex();
    index.setIncrement(1.3);
    index.increment(bounds, true);
    XCTAssertEqual(1, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(2, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(3, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(2, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(3, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(4, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(3, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(4, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(2, index.index());
}

- (void)testEndLooping {
    auto index = BufferIndex();
    index.setIncrement(1.3);
    index.increment(bounds, true);
    index.increment(bounds, true);
    index.increment(bounds, true);
    index.increment(bounds, true);
    index.increment(bounds, true);
    XCTAssertEqual(3, index.index());
    index.increment(bounds, true);
    XCTAssertEqual(4, index.index());
    index.increment(bounds, false);
    XCTAssertEqual(6, index.index());
    index.increment(bounds, false);
    XCTAssertEqual(6, index.index());
}

- (void)testFinished {
    auto index = BufferIndex();
    index.setIncrement(1.3);
    index.increment(bounds, false);
    XCTAssertEqual(1, index.index());
    index.increment(bounds, false);
    XCTAssertEqual(2, index.index());
    index.increment(bounds, false);
    XCTAssertEqual(3, index.index());
    index.increment(bounds, false);
    XCTAssertEqual(5, index.index());
    XCTAssertFalse(index.finished());
    index.increment(bounds, false);
    XCTAssertEqual(6, index.index());
    XCTAssertTrue(index.finished());
    index.increment(bounds, false);
    XCTAssertEqual(6, index.index());
}

@end
