// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSP.hpp"

using namespace SF2::DSP;

@interface DSPTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation DSPTests

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUnipolarModulation {
    XCTAssertEqual(unipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(unipolarModulation(0.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(unipolarModulation(0.5, 10.0, 20.0), 15.0);
    XCTAssertEqual(unipolarModulation(1.0, 10.0, 20.0), 20.0);
    XCTAssertEqual(unipolarModulation(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
    XCTAssertEqual(bipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(bipolarModulation(-1.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(bipolarModulation(0.0, 10.0, 20.0), 15.0);
    XCTAssertEqual(bipolarModulation(1.0, 10.0, 20.0), 20.0);

    XCTAssertEqual(bipolarModulation(-1.0, -20.0, 13.0), -20.0);
    XCTAssertEqual(bipolarModulation(0.0,  -20.0, 13.0), -3.5);
    XCTAssertEqual(bipolarModulation(1.0,  -20.0, 13.0), 13.0);
}

- (void)testUnipolarToBipolar {
    XCTAssertEqual(unipolarToBipolar(0.0), -1.0);
    XCTAssertEqual(unipolarToBipolar(0.5), 0.0);
    XCTAssertEqual(unipolarToBipolar(1.0), 1.0);
}

- (void)testBipolarToUnipolar {
    XCTAssertEqual(bipolarToUnipolar(-1.0), 0.0);
    XCTAssertEqual(bipolarToUnipolar(0.0), 0.5);
    XCTAssertEqual(bipolarToUnipolar(1.0), 1.0);
}

- (void)testPanLookup {
    double left, right;

    SF2::DSP::panLookup<double>(-501, left, right);
    XCTAssertEqualWithAccuracy(1.0, left, self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, right, self.epsilon);

    SF2::DSP::panLookup<double>(-500, left, right);
    XCTAssertEqualWithAccuracy(1.0, left, self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, right, self.epsilon);

    SF2::DSP::panLookup<double>(-100, left, right);
    XCTAssertEqualWithAccuracy(0.809016994375, left, self.epsilon);
    XCTAssertEqualWithAccuracy(0.587785252292, right, self.epsilon);

    SF2::DSP::panLookup<double>(0, left, right);
    XCTAssertEqualWithAccuracy(left, right, self.epsilon);

    SF2::DSP::panLookup<double>(100, left, right);
    XCTAssertEqualWithAccuracy(0.587785252292, left, self.epsilon);
    XCTAssertEqualWithAccuracy(0.809016994375, right, self.epsilon);

    SF2::DSP::panLookup<double>(500, left, right);
    XCTAssertEqualWithAccuracy(0.0, left, self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, right, self.epsilon);

    SF2::DSP::panLookup<double>(501, left, right);
    XCTAssertEqualWithAccuracy(0.0, left, self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, right, self.epsilon);
}

- (void)testParabolicSineAccuracy {
    for (int index = 0; index < 360.0; ++index) {
        auto theta = 2.0 * M_PI * index / 360.0 - M_PI;
        auto real = std::sin(theta);
        XCTAssertEqualWithAccuracy(SF2::DSP::parabolicSine(theta), real, 0.0011);
    }
}

- (void)testSinLookup {
    XCTAssertEqualWithAccuracy(0.0, sineLookup<double>(0.0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.707106768181, sineLookup<double>(QuarterPI), self.epsilon); // 45°
    XCTAssertEqualWithAccuracy(1.0, sineLookup<double>(HalfPI - 0.0000001), self.epsilon); // 90°
}

- (void)testSin {
    for (int degrees = -720; degrees <= 720; degrees += 10) {
        double radians = degrees * PI / 180.0;
        double value = sineLookup<double>(radians);
        // std::cout << degrees << " " << value << std::endl;
        XCTAssertEqualWithAccuracy(::std::sin(radians), value, self.epsilon);
    }
}

- (void)testCentFrequencyMultiplier {
    XCTAssertEqualWithAccuracy(0.5, centToFrequencyMultiplier<double>(-1200), self.epsilon); // -1200 = 1/2x
    XCTAssertEqualWithAccuracy(1.0, centToFrequencyMultiplier<double>(0), self.epsilon); // 0 = 1x
    XCTAssertEqualWithAccuracy(2.0, centToFrequencyMultiplier<double>(1200), self.epsilon); // +1200 = 2x
}

- (void)testCentToFrequency {
    XCTAssertEqualWithAccuracy(27.5, centToFrequency<double>(2100), self.epsilon); // A0
    XCTAssertEqualWithAccuracy(55.0, centToFrequency<double>(3300), self.epsilon); // A1
    XCTAssertEqualWithAccuracy(110.0, centToFrequency<double>(4500), self.epsilon); // A2
    XCTAssertEqualWithAccuracy(220.0, centToFrequency<double>(5700), self.epsilon); // A3
    XCTAssertEqualWithAccuracy(329.627556913, centToFrequency<double>(6400), self.epsilon); // C4
    XCTAssertEqualWithAccuracy(440.0, centToFrequency<double>(6900), self.epsilon); // A4
    XCTAssertEqualWithAccuracy(880.0, centToFrequency<double>(8100), self.epsilon); // A5
    XCTAssertEqualWithAccuracy(1760.0, centToFrequency<double>(9300), self.epsilon); // A6
    XCTAssertEqualWithAccuracy(3520.0, centToFrequency<double>(10500), self.epsilon); // A7
    XCTAssertEqualWithAccuracy(4186.00904481, centToFrequency<double>(10800), self.epsilon); // C8
}

- (void)testCentibelsToAttenuation {
    XCTAssertEqualWithAccuracy(1.0, centibelToAttenuation<double>(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.891250938134, centibelToAttenuation<double>(10), self.epsilon);
    XCTAssertEqualWithAccuracy(0.316227766017, centibelToAttenuation<double>(100), self.epsilon);
    XCTAssertEqualWithAccuracy(1e-05, centibelToAttenuation<double>(1000), self.epsilon);
    XCTAssertEqualWithAccuracy(6.3095734448e-08, centibelToAttenuation<double>(1440), self.epsilon);
    XCTAssertEqualWithAccuracy(1e-07, centibelToAttenuation<double>(1441), self.epsilon);
}

- (void)testCentibelsToGain {
    XCTAssertEqualWithAccuracy(1.0, centibelToGain<double>(0), self.epsilon);
    XCTAssertEqualWithAccuracy(1.1220184543, centibelToGain<double>(10), self.epsilon);
    XCTAssertEqualWithAccuracy(3.16227766017, centibelToGain<double>(100), self.epsilon);
    XCTAssertEqualWithAccuracy(100000, centibelToGain<double>(1000), self.epsilon);
    XCTAssertEqualWithAccuracy(15848931.924611142, centibelToGain<double>(1440), self.epsilon);
    XCTAssertEqualWithAccuracy(15848931.924611142, centibelToGain<double>(1441), self.epsilon);
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
