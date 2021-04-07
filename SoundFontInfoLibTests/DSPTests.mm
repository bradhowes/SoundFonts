// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSP.hpp"

@interface DSPTests : XCTestCase

@end

@implementation DSPTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUnipolarModulation {
    XCTAssertEqual(SF2::DSP::unipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(0.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(0.5, 10.0, 20.0), 15.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(1.0, 10.0, 20.0), 20.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
    XCTAssertEqual(SF2::DSP::bipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(-1.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(0.0, 10.0, 20.0), 15.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(1.0, 10.0, 20.0), 20.0);

    XCTAssertEqual(SF2::DSP::bipolarModulation(-1.0, -20.0, 13.0), -20.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(0.0,  -20.0, 13.0), -3.5);
    XCTAssertEqual(SF2::DSP::bipolarModulation(1.0,  -20.0, 13.0), 13.0);
}

- (void)testUnipolarToBipolar {
    XCTAssertEqual(SF2::DSP::unipolarToBipolar(0.0), -1.0);
    XCTAssertEqual(SF2::DSP::unipolarToBipolar(0.5), 0.0);
    XCTAssertEqual(SF2::DSP::unipolarToBipolar(1.0), 1.0);
}

- (void)testBipolarToUnipolar {
    XCTAssertEqual(SF2::DSP::bipolarToUnipolar(-1.0), 0.0);
    XCTAssertEqual(SF2::DSP::bipolarToUnipolar(0.0), 0.5);
    XCTAssertEqual(SF2::DSP::bipolarToUnipolar(1.0), 1.0);
}

- (void)testParabolicSineAccuracy {
    for (int index = 0; index < 360.0; ++index) {
        auto theta = 2.0 * M_PI * index / 360.0 - M_PI;
        auto real = std::sin(theta);
        XCTAssertEqualWithAccuracy(SF2::DSP::parabolicSine(theta), real, 0.0011);
    }
}

- (void)testInterpolationCubic4thOrderWeights {
    double epsilon = 0.0000001;
    auto v = SF2::DSP::Interpolation::Cubic4thOrder<double>::weights[0];
    XCTAssertEqualWithAccuracy(v[0], 0.0, epsilon);
    XCTAssertEqualWithAccuracy(v[1], 1.0, epsilon);
    XCTAssertEqualWithAccuracy(v[2], 0.0, epsilon);
    XCTAssertEqualWithAccuracy(v[3], 0.0, epsilon);

    v = SF2::DSP::Interpolation::Cubic4thOrder<double>::weights[128];
    XCTAssertEqualWithAccuracy(v[0], -0.0625, epsilon);
    XCTAssertEqualWithAccuracy(v[1],  0.5625, epsilon);
    XCTAssertEqualWithAccuracy(v[2],  0.5625, epsilon);
    XCTAssertEqualWithAccuracy(v[3], -0.0625, epsilon);

    v = SF2::DSP::Interpolation::Cubic4thOrder<double>::weights[SF2::DSP::Interpolation::Cubic4thOrder<double>::weightsCount - 1];
    XCTAssertEqualWithAccuracy(v[0], -7.599592208862305e-06, epsilon);
    XCTAssertEqualWithAccuracy(v[1], 0.001983553171157837, epsilon);
    XCTAssertEqualWithAccuracy(v[2], 0.9999619424343109, epsilon);
    XCTAssertEqualWithAccuracy(v[3], -0.0019378960132598877, epsilon);

}

- (void)testInterpolationCubic4thOrderInterpolate {
    double epsilon = 0.0000001;

    auto v = SF2::DSP::Interpolation::Cubic4thOrder<double>::interpolate(0.0, 1, 2, 3, 4);
    XCTAssertEqualWithAccuracy(2.0, v, epsilon);

    v = SF2::DSP::Interpolation::Cubic4thOrder<double>::interpolate(0.5, 1, 2, 3, 4);
    XCTAssertEqualWithAccuracy(1 * -0.0625 + 2 * 0.5625 + 3 * 0.5625 + 4 * -0.0625, v, epsilon);

    v = SF2::DSP::Interpolation::Cubic4thOrder<double>::interpolate(0.99999, 1, 2, 3, 4);
    XCTAssertEqualWithAccuracy(2.99609375, v, epsilon);
}

- (void)testInterpolationLinearInterpolate {
    double epsilon = 0.0000001;

    auto v = SF2::DSP::Interpolation::Linear<double>::interpolate(0.0, 1, 2);
    XCTAssertEqualWithAccuracy(1.0, v, epsilon);

    v = SF2::DSP::Interpolation::Linear<double>::interpolate(0.5, 1, 2);
    XCTAssertEqualWithAccuracy(0.5 * 1.0 + 0.5 * 2.0, v, epsilon);

    v = SF2::DSP::Interpolation::Linear<double>::interpolate(0.9, 1, 2);
    XCTAssertEqualWithAccuracy(0.1 * 1.0 + 0.9 * 2.0, v, epsilon);
}

@end
