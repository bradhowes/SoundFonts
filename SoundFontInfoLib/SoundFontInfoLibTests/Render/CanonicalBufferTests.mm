// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Types.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Sample/Generator.hpp"

using namespace SF2::Render::Sample;
using namespace SF2::Render::Voice;

@interface CanonicalBufferTests : XCTestCase

@end

@implementation CanonicalBufferTests

static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);
static SF2::MIDI::Channel channel;
static int16_t values[8] = {10000, 20000, 30000, 20000, 10000, -10000, -20000, -30000};

- (void)testLoading {
  CanonicalBuffer buffer{values, header};
  XCTAssertFalse(buffer.isLoaded());
  buffer.load();
  XCTAssertTrue(buffer.isLoaded());
}

- (void)testLinearInterpolation {
  State state{100, channel, 69, 64};
  CanonicalBuffer buffer{values, header};
  Generator gen{state.sampleRate(), buffer, Bounds::make(buffer.header(), state), Generator::Interpolator::linear};
  buffer.load();

  XCTAssertEqualWithAccuracy(0.30517578125, gen.generate(0.0, true), 0.0000001);
  XCTAssertEqualWithAccuracy(0.701904296875, gen.generate(0.0, true), 0.0000001);
  XCTAssertEqualWithAccuracy(0.732421875, gen.generate(0.0, true), 0.0000001);
  XCTAssertEqualWithAccuracy(0.335693359375, gen.generate(0.0, true), 0.0000001);
}

- (void)testCubicInterpolation {
  State state{100, channel, 69, 64};
  CanonicalBuffer buffer{values, header};
  Generator gen{state.sampleRate(), buffer, Bounds::make(buffer.header(), state),
    Generator::Interpolator::cubic4thOrder};
  buffer.load();

  XCTAssertEqualWithAccuracy(0.30517578125, gen.generate(0.0, false), 0.0000001);
  XCTAssertEqualWithAccuracy(0.721051098083, gen.generate(0.0, false), 0.0000001);
  XCTAssertEqualWithAccuracy(0.761876096931, gen.generate(0.0, false), 0.0000001);
  XCTAssertEqualWithAccuracy(0.348288029812, gen.generate(0.0, false), 0.0000001);
}

@end

