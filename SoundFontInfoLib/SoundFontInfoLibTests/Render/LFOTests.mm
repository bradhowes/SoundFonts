// Copyright © 2021 Brad Howes. All rights reserved.

#import <vector>

#import "SampleBasedTestCase.h"
#import "Render/LFO.hpp"

using namespace SF2::Render;

@interface LFOTests : SampleBasedTestCase
@end

@implementation LFOTests

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSamples {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.0).make();
  [self sample:osc.value() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.value() equals:0.5];
  [self sample:osc.value() equals:0.5];
  [self sample:osc.valueAndIncrement() equals:0.5];
  [self sample:osc.value() equals:1.0];
  [self sample:osc.value() equals:1.0];
  [self sample:osc.valueAndIncrement() equals:1.0];
  [self sample:osc.valueAndIncrement() equals:0.5];
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:-0.5];
  [self sample:osc.valueAndIncrement() equals:-1.0];
  [self sample:osc.valueAndIncrement() equals:-0.5];
  [self sample:osc.valueAndIncrement() equals:0.0];
}

- (void)testDelay {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.125).make();
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.5];
  osc.setDelay(0.25);
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.5];
}

- (void)testConfig {
  auto osc = LFO::Config(8.0).frequency(1.0).delay(0.125).make();
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.5];
  osc = LFO::Config(8.0).frequency(1.0).delay(0.0).make();
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.5];
  osc = LFO::Config(8.0).frequency(2.0).make();
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:1.0];
  osc = LFO::Config(8.0).frequency(1.0).make();
  [self sample:osc.valueAndIncrement() equals:0.0];
  [self sample:osc.valueAndIncrement() equals:0.5];
  [self sample:osc.valueAndIncrement() equals:1.0];
}

@end
