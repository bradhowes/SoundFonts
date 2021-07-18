// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <vector>

#import "Render/LFO.hpp"

#define SamplesEqual(A, B) XCTAssertEqualWithAccuracy(A, B, _epsilon)

using namespace SF2::Render;

@interface LFOTests : XCTestCase
@property float epsilon;
@end

@implementation LFOTests

- (void)setUp {
  _epsilon = 0.0001;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSamples {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.0).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  SamplesEqual(osc.valueAndIncrement(), 1.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), -0.5);
  SamplesEqual(osc.valueAndIncrement(), -1.0);
  SamplesEqual(osc.valueAndIncrement(), -0.5);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
}

- (void)testSaveRestore {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.0).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  auto state = osc.saveState();
  SamplesEqual(osc.valueAndIncrement(), 1.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  osc.restoreState(state);
  SamplesEqual(osc.valueAndIncrement(), 1.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
}

- (void)testDelay {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.125).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  osc.setDelay(0.25);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
}

- (void)testConfig {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.125).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  osc = LFO::Config(8.0).frequency(1.0).delay(0.0).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  osc = LFO::Config(8.0).frequency(2.0).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 1.0);
  osc = LFO::Config(8.0).frequency(1.0).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  SamplesEqual(osc.valueAndIncrement(), 1.0);
  osc = LFO::Config(8.0).frequency(1.0).make();
  SamplesEqual(osc.valueAndIncrement(), 0.0);
  SamplesEqual(osc.valueAndIncrement(), 0.5);
  SamplesEqual(osc.valueAndIncrement(), 1.0);
}

@end
