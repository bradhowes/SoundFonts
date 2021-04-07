// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Render/SampleBuffer.hpp"

@interface SampleBufferTests : XCTestCase

@end

@implementation SampleBufferTests

static SF2::Entity::SampleHeader header(0, 6, 2, 5, 100, 69, 0);

- (void)setUp {
}

- (void)tearDown {
}

- (void)testLinearInterpolation {
    int16_t values[8] = {10000, 20000, 30000, 20000, 10000, -10000, -20000, -30000};
    auto buffer = SF2::Render::SampleBuffer<float>(values, header,
                                                   SF2::Render::SampleBuffer<float>::Interpolator::linear);
    buffer.load();
    auto index = SF2::Render::SampleIndex(header, 1.3);
    XCTAssertEqualWithAccuracy(0.305176, buffer.read(index, true), 0.00001);
    XCTAssertEqual(1, index.index());
    XCTAssertEqualWithAccuracy(0.701904, buffer.read(index, true), 0.00001);
    XCTAssertEqual(2, index.index());
    XCTAssertEqualWithAccuracy(0.732422, buffer.read(index, true), 0.00001);
    XCTAssertEqual(3, index.index());
    XCTAssertEqualWithAccuracy(0.335693, buffer.read(index, true), 0.00001);
    XCTAssertEqual(2, index.index());
}

- (void)testCubicInterpolation {
    int16_t values[8] = {10000, 20000, 30000, 20000, 10000, -10000, -20000, -30000};
    auto buffer = SF2::Render::SampleBuffer<float>(values, header,
                                                   SF2::Render::SampleBuffer<float>::Interpolator::cubic4thOrder);
    buffer.load();
    auto index = SF2::Render::SampleIndex(header, 1.3);
    XCTAssertEqualWithAccuracy(0.305176, buffer.read(index, false), 0.00001);
    XCTAssertEqual(1, index.index());
    XCTAssertEqualWithAccuracy(0.719862, buffer.read(index, false), 0.00001);
    XCTAssertEqual(2, index.index());
    XCTAssertEqualWithAccuracy(0.762662, buffer.read(index, false), 0.00001);
    XCTAssertEqual(3, index.index());
    XCTAssertEqualWithAccuracy(0.348679, buffer.read(index, false), 0.00001);
    XCTAssertEqual(5, index.index());
}


@end

