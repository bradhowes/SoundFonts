// Copyright © 2021 Brad Howes. All rights reserved.

#import <vector>

#import "SampleBasedTestCase.h"
#import "Types.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Sample/Generator.hpp"

using namespace SF2::Render::Sample;
using namespace SF2::Render::Voice;

@interface CanonicalBufferTests : SampleBasedTestCase
@end

@implementation CanonicalBufferTests

static double sampleRate{76.9230769231};
static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);
static SF2::MIDI::Channel channel;
static int16_t values[8] = {10000, 20000, 30000, 20000, 10000, -10000, -20000, -30000};

- (void)setUp {
}

- (void)tearDown {
}

- (void)testLoading {
  CanonicalBuffer buffer{values, header};
  XCTAssertFalse(buffer.isLoaded());
  buffer.load();
  XCTAssertTrue(buffer.isLoaded());
}

- (void)testLinearInterpolation {
  CanonicalBuffer buffer{values, header};
  State state{sampleRate, channel, 69, 64};
  Bounds bounds{Bounds::make(header, state)};
  Generator gen{sampleRate, buffer, bounds};
  buffer.load();
  XCTAssertEqualWithAccuracy(0.30517578125, gen.generate(0.0, true), 0.0000001);
  XCTAssertEqualWithAccuracy(0.312547537086, gen.generate(0.0, true), 0.0000001);
  XCTAssertEqualWithAccuracy(0.319919292922, gen.generate(0.0, true), 0.0000001);
  XCTAssertEqualWithAccuracy(0.327291048758, gen.generate(0.0, true), 0.0000001);
}

- (void)testCubicInterpolation {
  CanonicalBuffer buffer{values, header};
  State state{sampleRate, channel, 69, 64};
  Bounds bounds{Bounds::make(header, state)};
  Generator gen{sampleRate, buffer, bounds, Generator::Interpolator::cubic4thOrder};
  buffer.load();
  XCTAssertEqualWithAccuracy(0.30517578125, gen.generate(0.0, false), 0.0000001);
  XCTAssertEqualWithAccuracy(0.312328338623, gen.generate(0.0, false), 0.0000001);
  XCTAssertEqualWithAccuracy(0.31977891922, gen.generate(0.0, false), 0.0000001);
  XCTAssertEqualWithAccuracy(0.327229499817, gen.generate(0.0, false), 0.0000001);
}

@end

