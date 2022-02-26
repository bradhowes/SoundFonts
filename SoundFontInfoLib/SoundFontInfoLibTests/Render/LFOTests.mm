// Copyright © 2021 Brad Howes. All rights reserved.

#import <vector>

#import "SampleBasedContexts.hpp"
#import "Render/LFO.hpp"

using namespace SF2::Render;

namespace SF2::Render {
struct LFOTestInjector {
  static LFO make(Float sampleRate, Float frequency, Float delay) {
    return LFO(sampleRate, frequency, delay);
  }
};
}

@interface LFOTests : XCTestCase
@end

@implementation LFOTests {
  SampleBasedContexts contexts;
  SF2::Float epsilon;
}

- (void)setUp {
  epsilon = 1.0e-8f;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSamples {
  auto osc = LFOTestInjector::make(8.0, 1.0, 0.0);
  XCTAssertEqualWithAccuracy(osc.value(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.value(), 0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.value(), 0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.value(), 1.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.value(), 1.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 1.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), -0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), -1.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), -0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
}

- (void)testDelay {
  auto osc = LFOTestInjector::make(8.0, 1.0, 0.125);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
  osc = LFOTestInjector::make(8.0, 1.0, 0.25);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
}

- (void)testConfig {
  auto osc = LFOTestInjector::make(8.0, 1.0, 0.125);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
  osc = LFOTestInjector::make(8.0, 1.0, 0.0);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
  osc = LFOTestInjector::make(8.0, 2.0, 0.0);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 1.0, epsilon);
  osc = LFOTestInjector::make(8.0, 1.0, 0.0);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.0, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 0.5, epsilon);
  XCTAssertEqualWithAccuracy(osc.getNextValue(), 1.0, epsilon);
}

@end
