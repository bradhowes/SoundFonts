// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Render/Sample/Generator.hpp"

using namespace SF2::Render::Sample;
using namespace SF2::Render::Voice;

@interface SampleBufferTests : XCTestCase

@end

@implementation SampleBufferTests

static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);
static int16_t values[8] = {10000, 20000, 30000, 20000, 10000, -10000, -20000, -30000};
static CanonicalBuffer<float> buffer{values, header};

- (void)setUp {
}

- (void)tearDown {
}

- (void)testLinearInterpolation {
    Generator gen{buffer, State(76.9230769231, 69, 64)};
    buffer.load();
    XCTAssertEqualWithAccuracy(0.305176, gen.generate(true), 0.00001);
    XCTAssertEqualWithAccuracy(0.701904, gen.generate(true), 0.00001);
    XCTAssertEqualWithAccuracy(0.732422, gen.generate(true), 0.00001);
    XCTAssertEqualWithAccuracy(0.335693, gen.generate(true), 0.00001);
}

- (void)testCubicInterpolation {
    Generator gen{buffer, State(76.9230769231, 69, 64), Generator<float>::Interpolator::cubic4thOrder};
    buffer.load();
    XCTAssertEqualWithAccuracy(0.305176, gen.generate(false), 0.00001);
    XCTAssertEqualWithAccuracy(0.719862, gen.generate(false), 0.00001);
    XCTAssertEqualWithAccuracy(0.762662, gen.generate(false), 0.00001);
    XCTAssertEqualWithAccuracy(0.348679, gen.generate(false), 0.00001);
}

@end

