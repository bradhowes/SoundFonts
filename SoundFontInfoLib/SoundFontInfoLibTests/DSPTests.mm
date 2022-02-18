// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#include "Types.hpp"
#include "DSP/DSP.hpp"
#include "FluidSynthTruths.hpp"

using namespace SF2;
using namespace SF2::DSP;
using namespace SF2::DSP::Tables;

@interface DSPTests : XCTestCase
@property (nonatomic, assign) SF2::Float epsilon;
@end

@implementation DSPTests

- (void)setUp {
  self.epsilon = 0.0000001;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testClampFilterCutoff {
  XCTAssertEqual(1500, clampFilterCutoff(0));
  XCTAssertEqual(20000, clampFilterCutoff(22000));
  XCTAssertEqual(3000, clampFilterCutoff(3000));
  XCTAssertEqual(14000, clampFilterCutoff(14000));
}

- (void)testUnipolarModulation {
  XCTAssertEqual(unipolarModulate(-3.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(unipolarModulate(0.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(unipolarModulate(0.5, 10.0, 20.0), 15.0);
  XCTAssertEqual(unipolarModulate(1.0, 10.0, 20.0), 20.0);
  XCTAssertEqual(unipolarModulate(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
  XCTAssertEqual(bipolarModulate(-3.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(bipolarModulate(-1.0, 10.0, 20.0), 10.0);
  XCTAssertEqual(bipolarModulate(0.0, 10.0, 20.0), 15.0);
  XCTAssertEqual(bipolarModulate(1.0, 10.0, 20.0), 20.0);
  XCTAssertEqual(bipolarModulate(-1.0, -20.0, 13.0), -20.0);
  XCTAssertEqual(bipolarModulate(0.0,  -20.0, 13.0), -3.5);
  XCTAssertEqual(bipolarModulate(1.0,  -20.0, 13.0), 13.0);
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
  SF2::Float left, right;
  
  SF2::DSP::panLookup(-501, left, right);
  XCTAssertEqualWithAccuracy(1.0, left, self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, right, self.epsilon);
  
  SF2::DSP::panLookup(-500, left, right);
  XCTAssertEqualWithAccuracy(1.0, left, self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, right, self.epsilon);
  
  SF2::DSP::panLookup(-100, left, right);
  XCTAssertEqualWithAccuracy(0.809016994375, left, self.epsilon);
  XCTAssertEqualWithAccuracy(0.587785252292, right, self.epsilon);
  
  SF2::DSP::panLookup(0, left, right);
  XCTAssertEqualWithAccuracy(left, right, self.epsilon);

  SF2::DSP::panLookup(100, left, right);
  XCTAssertEqualWithAccuracy(0.587785252292, left, self.epsilon);
  XCTAssertEqualWithAccuracy(0.809016994375, right, self.epsilon);
  
  SF2::DSP::panLookup(500, left, right);
  XCTAssertEqualWithAccuracy(0.0, left, self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, right, self.epsilon);
  
  SF2::DSP::panLookup(501, left, right);
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
  XCTAssertEqualWithAccuracy(0.0, sineLookup(0.0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.707106768181, sineLookup(QuarterPI), self.epsilon); // 45°
  XCTAssertEqualWithAccuracy(1.0, sineLookup(HalfPI - 0.0000001), self.epsilon); // 90°
}

- (void)testSin {
  for (int degrees = -720; degrees <= 720; degrees += 10) {
    Float radians = degrees * PI / 180.0;
    Float value = sineLookup(radians);
    // std::cout << degrees << " " << value << std::endl;
    XCTAssertEqualWithAccuracy(::std::sin(radians), value, self.epsilon);
  }
}

- (void)testCentToFrequency {
  XCTAssertEqualWithAccuracy(1.0, centsToFrequency(-1), self.epsilon); // A0
  XCTAssertEqualWithAccuracy(centsToFrequency(-1), fluid_ct2hz_real(-1), self.epsilon); // A0

  XCTAssertEqualWithAccuracy(8.17579891564, centsToFrequency(0), self.epsilon); // A0
  XCTAssertEqualWithAccuracy(centsToFrequency(0), fluid_ct2hz_real(0), self.epsilon); // A0

  XCTAssertEqualWithAccuracy(55.0, centsToFrequency(3300), self.epsilon); // A1
  XCTAssertEqualWithAccuracy(centsToFrequency(3300), fluid_ct2hz_real(3300), self.epsilon); // A1

  XCTAssertEqualWithAccuracy(110.0, centsToFrequency(4500), self.epsilon); // A2
  XCTAssertEqualWithAccuracy(centsToFrequency(4500), fluid_ct2hz_real(4500), self.epsilon); // A2

  XCTAssertEqualWithAccuracy(220.0, centsToFrequency(5700), self.epsilon); // A3
  XCTAssertEqualWithAccuracy(centsToFrequency(5700), fluid_ct2hz_real(5700), self.epsilon); // A3

  XCTAssertEqualWithAccuracy(329.627556913, centsToFrequency(6400), self.epsilon); // C4
  XCTAssertEqualWithAccuracy(centsToFrequency(6400), fluid_ct2hz_real(6400), self.epsilon); // C4

  XCTAssertEqualWithAccuracy(440.0, centsToFrequency(6900), self.epsilon); // A4
  XCTAssertEqualWithAccuracy(centsToFrequency(6900), fluid_ct2hz_real(6900), self.epsilon); // A4

  XCTAssertEqualWithAccuracy(880.0, centsToFrequency(8100), self.epsilon); // A5
  XCTAssertEqualWithAccuracy(centsToFrequency(8100), fluid_ct2hz_real(8100), self.epsilon); // A5

  XCTAssertEqualWithAccuracy(1760.0, centsToFrequency(9300), self.epsilon); // A6
  XCTAssertEqualWithAccuracy(centsToFrequency(9300), fluid_ct2hz_real(9300), self.epsilon); // A6

  XCTAssertEqualWithAccuracy(3520.0, centsToFrequency(10500), self.epsilon); // A7
  XCTAssertEqualWithAccuracy(centsToFrequency(10500), fluid_ct2hz_real(10500), self.epsilon); // A7

  XCTAssertEqualWithAccuracy(4186.00904481, centsToFrequency(10800), self.epsilon); // C8
  XCTAssertEqualWithAccuracy(centsToFrequency(10800), fluid_ct2hz_real(10800), self.epsilon); // C8

  XCTAssertEqualWithAccuracy(centsToFrequency(6901), fluid_ct2hz_real(6901), self.epsilon);
  XCTAssertEqualWithAccuracy(centsToFrequency(6923), fluid_ct2hz_real(6923), self.epsilon);
  XCTAssertEqualWithAccuracy(centsToFrequency(6999), fluid_ct2hz_real(6999), self.epsilon);
}

- (void)testCentsFrequncyScalingLookup {
  XCTAssertEqualWithAccuracy(0.5, CentsFrequencyScalingLookup::convert(-1200), self.epsilon); // ⬇️ Octave
  XCTAssertEqualWithAccuracy(std::sqrt(2.0) / 2.0, CentsFrequencyScalingLookup::convert(-600), self.epsilon); // ⬇️ 1/2
  XCTAssertEqualWithAccuracy(1.0, CentsFrequencyScalingLookup::convert(0), self.epsilon); // No change
  XCTAssertEqualWithAccuracy(std::sqrt(2.0), CentsFrequencyScalingLookup::convert(600), self.epsilon); // ⬆️ 1/2
  XCTAssertEqualWithAccuracy(2.0, CentsFrequencyScalingLookup::convert(1200), self.epsilon); // ⬆️ Octave
}

- (void)testCentibelsToAttenuation {
  XCTAssertEqualWithAccuracy(1.0, centibelsToAttenuation(-1), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, centibelsToAttenuation(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.891250938134, centibelsToAttenuation(10), self.epsilon);
  XCTAssertEqualWithAccuracy(0.316227766017, centibelsToAttenuation(100), self.epsilon);
  XCTAssertEqualWithAccuracy(1e-05, centibelsToAttenuation(1000), self.epsilon);
  XCTAssertEqualWithAccuracy(6.3095734448e-08, centibelsToAttenuation(1440), self.epsilon);
  XCTAssertEqualWithAccuracy(1e-07, centibelsToAttenuation(1441), self.epsilon);
}

- (void)testCentibelsToGain {
  XCTAssertEqualWithAccuracy(1.0, centibelsToGain(0), self.epsilon);
  XCTAssertEqualWithAccuracy(1.1220184543, centibelsToGain(10), self.epsilon);
  XCTAssertEqualWithAccuracy(3.16227766017, centibelsToGain(100), self.epsilon);
  XCTAssertEqualWithAccuracy(100000, centibelsToGain(1000), self.epsilon);
  XCTAssertEqualWithAccuracy(15848931.924611142, centibelsToGain(1440), self.epsilon);
  XCTAssertEqualWithAccuracy(15848931.924611142, centibelsToGain(1441), self.epsilon);
}

- (void)testInterpolationCubic4thOrderInterpolate {
  Float epsilon = 0.0000001;
  
  auto v = SF2::DSP::Interpolation::cubic4thOrder(0.0, 1, 2, 3, 4);
  XCTAssertEqualWithAccuracy(2.0, v, epsilon);
  
  v = SF2::DSP::Interpolation::cubic4thOrder(0.5, 1, 2, 3, 4);
  XCTAssertEqualWithAccuracy(1 * -0.0625 + 2 * 0.5625 + 3 * 0.5625 + 4 * -0.0625, v, epsilon);
  
  v = SF2::DSP::Interpolation::cubic4thOrder(0.99999, 1, 2, 3, 4);
  XCTAssertEqualWithAccuracy(2.9990234375, v, epsilon);
}

- (void)testInterpolationLinearInterpolate {
  Float epsilon = 0.0000001;
  
  auto v = SF2::DSP::Interpolation::linear(0.0, 1, 2);
  XCTAssertEqualWithAccuracy(1.0, v, epsilon);
  
  v = SF2::DSP::Interpolation::linear(0.5, 1, 2);
  XCTAssertEqualWithAccuracy(0.5 * 1.0 + 0.5 * 2.0, v, epsilon);
  
  v = SF2::DSP::Interpolation::linear(0.9, 1, 2);
  XCTAssertEqualWithAccuracy(0.1 * 1.0 + 0.9 * 2.0, v, epsilon);
}

- (void)testTenthPercentage {
  XCTAssertEqualWithAccuracy(0.0, SF2::DSP::tenthPercentage(-1), 0.0001);
  XCTAssertEqualWithAccuracy(0.0, SF2::DSP::tenthPercentage(0), 0.0001);
  XCTAssertEqualWithAccuracy(0.123, SF2::DSP::tenthPercentage(123), 0.0001);
  XCTAssertEqualWithAccuracy(1.0, SF2::DSP::tenthPercentage(1000), 0.0001);
  XCTAssertEqualWithAccuracy(1.0, SF2::DSP::tenthPercentage(1001), 0.0001);
}

- (void)testCentsToFrequency {
  XCTAssertEqualWithAccuracy(0.000792, SF2::DSP::absoluteCentsToFrequency(-32768), 0.000001);
  XCTAssertEqualWithAccuracy(0.000792, SF2::DSP::absoluteCentsToFrequency(-20000), 0.000001);
  XCTAssertEqualWithAccuracy(8.175799, SF2::DSP::absoluteCentsToFrequency(0), 0.00001);
  XCTAssertEqualWithAccuracy(110.0, SF2::DSP::absoluteCentsToFrequency(4500), 0.00001);
  XCTAssertEqualWithAccuracy(110.0, SF2::DSP::absoluteCentsToFrequency(9000), 0.00001);
}

@end
