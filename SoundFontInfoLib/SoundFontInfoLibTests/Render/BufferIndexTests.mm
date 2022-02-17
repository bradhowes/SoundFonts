// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import "SampleBasedTestCase.h"

#import "Entity/SampleHeader.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Sample/BufferIndex.hpp"
#import "Render/State.hpp"

using namespace SF2::Render;
using namespace SF2::Render::Sample;

@interface SampleIndexTests : SampleBasedTestCase
@end

@implementation SampleIndexTests

static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);
static SF2::MIDI::Channel channel;
static Bounds bounds{Bounds::make(header, State(44100.0, channel))};

- (void)testConstruction {
  auto index = BufferIndex(bounds);
  XCTAssertEqual(0, index.pos());
  XCTAssertEqual(0, index.partial());
}

- (void)testIncrement {
  auto index = BufferIndex(bounds);
  index.setIncrement(1.3);
  index.increment(true);
  XCTAssertEqual(1, index.pos());
  index.increment(true);
  XCTAssertEqual(2, index.pos());
  XCTAssertEqualWithAccuracy(0.6, index.partial(), 0.000001);
}

- (void)testLooping {
  auto index = BufferIndex(bounds);
  index.setIncrement(1.3);
  index.increment(true);
  XCTAssertEqual(1, index.pos());
  index.increment(true);
  XCTAssertEqual(2, index.pos());
  index.increment(true);
  XCTAssertEqual(3, index.pos());
  index.increment(true);
  XCTAssertEqual(2, index.pos());
  index.increment(true);
  XCTAssertEqual(3, index.pos());
  index.increment(true);
  XCTAssertEqual(4, index.pos());
  index.increment(true);
  XCTAssertEqual(3, index.pos());
  index.increment(true);
  XCTAssertEqual(4, index.pos());
  index.increment(true);
  XCTAssertEqual(2, index.pos());
}

- (void)testEndLooping {
  auto index = BufferIndex(bounds);
  index.setIncrement(1.3);
  index.increment(true);
  index.increment(true);
  index.increment(true);
  index.increment(true);
  index.increment(true);
  XCTAssertEqual(3, index.pos());
  index.increment(true);
  XCTAssertEqual(4, index.pos());
  index.increment(false);
  XCTAssertEqual(6, index.pos());
  index.increment(false);
  XCTAssertEqual(6, index.pos());
}

- (void)testFinished {
  auto index = BufferIndex(bounds);
  index.setIncrement(1.3);
  index.increment(false);
  XCTAssertEqual(1, index.pos());
  index.increment(false);
  XCTAssertEqual(2, index.pos());
  index.increment(false);
  XCTAssertEqual(3, index.pos());
  index.increment(false);
  XCTAssertEqual(5, index.pos());
  XCTAssertFalse(index.finished());
  index.increment(false);
  XCTAssertEqual(6, index.pos());
  XCTAssertTrue(index.finished());
  index.increment(false);
  XCTAssertEqual(6, index.pos());
}

@end
