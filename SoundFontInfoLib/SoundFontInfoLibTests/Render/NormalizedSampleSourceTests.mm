// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Types.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Sample/Generator.hpp"

using namespace SF2::Render;

@interface NormalizedSampleSourceTests : XCTestCase

@end

@implementation NormalizedSampleSourceTests

static SF2::Entity::SampleHeader header{0, 6, 2, 5, 100, 69, 0}; // 0: start, 1: end, 2: loop start, 3: loop end
static SF2::MIDI::Channel channel;
static int16_t values[8] = {10000, -20000, 30000, 20000, 10000, -10000, -20000, -30000};

- (void)testLoading {
  NormalizedSampleSource source{values, header};
  XCTAssertEqual(source.size(), 0);
  XCTAssertFalse(source.isLoaded());
  XCTAssertEqual(0, source.header().startIndex());
  XCTAssertEqual(6, source.header().endIndex());

  source.load();

  XCTAssertTrue(source.isLoaded());
  XCTAssertEqual(source.size(), source.header().endIndex());
  XCTAssertEqual(source[0], values[0] * NormalizedSampleSource::normalizationScale);
  XCTAssertEqual(source[1], values[1] * NormalizedSampleSource::normalizationScale);
}

//- (void)testLinearInterpolation {
//  State state{100, channel};
//  NormalizedSampleSource source{values, header};
//  source.load();
//
//  // XCTAssertEqualWithAccuracy(0.30517578125, gen.generate(0.0, true), 0.0000001);
//#if 0
//  XCTAssertEqualWithAccuracy(0.701904296875, gen.generate(0.0, true), 0.0000001);
//  XCTAssertEqualWithAccuracy(0.732421875, gen.generate(0.0, true), 0.0000001);
//  XCTAssertEqualWithAccuracy(0.335693359375, gen.generate(0.0, true), 0.0000001);
//#endif
//}
//
//- (void)testCubicInterpolation {
//  State state{100, channel};
//  NormalizedSampleSource source{values, header};
//  source.load();
//
//  // XCTAssertEqualWithAccuracy(0.30517578125, gen.generate(0.0, false), 0.0000001);
//#if 0
//  XCTAssertEqualWithAccuracy(0.721051098083, gen.generate(0.0, false), 0.0000001);
//  XCTAssertEqualWithAccuracy(0.761876096931, gen.generate(0.0, false), 0.0000001);
//  XCTAssertEqualWithAccuracy(0.348288029812, gen.generate(0.0, false), 0.0000001);
//#endif
//}

@end

