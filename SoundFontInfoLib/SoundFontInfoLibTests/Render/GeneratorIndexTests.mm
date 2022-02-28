// Copyright © 2020 Brad Howes. All rights reserved.

#include <iostream>

#include "SampleBasedContexts.hpp"

#include "Entity/SampleHeader.hpp"
#include "MIDI/Channel.hpp"
#include "Render/Voice/Sample/Index.hpp"
#include "Render/Voice/State/State.hpp"

using namespace SF2::Render;
using namespace SF2::Render::Voice;
using namespace SF2::Render::Voice::Sample;

@interface GeneratorIndexTests : XCTestCase
@end

@implementation GeneratorIndexTests

static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);
static SF2::MIDI::Channel channel;
static Bounds bounds{Bounds::make(header, State::State(44100.0, channel))};

- (void)testConstruction {
  auto index = Index();
  XCTAssertEqual(0, index.whole());
  XCTAssertEqual(0, index.partial());
}

- (void)testIncrement {
  auto index = Index();
  auto increment = 1.3;
  index.configure(bounds);
  index.increment(increment, true);
  XCTAssertEqual(1, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(2, index.whole());
  XCTAssertEqualWithAccuracy(0.6, index.partial(), 0.000001);
}

- (void)testLooping {
  auto index = Index();
  auto increment = 1.3;
  index.configure(bounds);
  index.increment(increment, true);
  XCTAssertEqual(1, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(2, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(3, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(2, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(3, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(4, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(3, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(4, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(2, index.whole());
}

- (void)testEndLooping {
  auto index = Index();
  auto increment = 1.3;
  index.configure(bounds);
  index.increment(increment, true);
  index.increment(increment, true);
  index.increment(increment, true);
  index.increment(increment, true);
  index.increment(increment, true);
  XCTAssertEqual(3, index.whole());
  index.increment(increment, true);
  XCTAssertEqual(4, index.whole());
  index.increment(increment, false);
  XCTAssertEqual(6, index.whole());
  index.increment(increment, false);
  XCTAssertEqual(6, index.whole());
}

- (void)testFinished {
  auto index = Index();
  auto increment = 1.3;
  index.configure(bounds);
  index.increment(increment, false);
  XCTAssertEqual(1, index.whole());
  index.increment(increment, false);
  XCTAssertEqual(2, index.whole());
  index.increment(increment, false);
  XCTAssertEqual(3, index.whole());
  index.increment(increment, false);
  XCTAssertEqual(5, index.whole());
  XCTAssertFalse(index.finished());
  index.increment(increment, false);
  XCTAssertEqual(6, index.whole());
  XCTAssertTrue(index.finished());
  index.increment(increment, false);
  XCTAssertEqual(6, index.whole());
}

@end
