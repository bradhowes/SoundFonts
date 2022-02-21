// Copyright © 2021 Brad Howes. All rights reserved.

#import <vector>

#import "SampleBasedContexts.h"
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
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSamples {
  auto osc = LFOTestInjector::make(8.0, 1.0, 0.0);
  [self sample:osc.value() equals:0.0];
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.value() equals:0.5];
  [self sample:osc.value() equals:0.5];
  [self sample:osc.getNextValue() equals:0.5];
  [self sample:osc.value() equals:1.0];
  [self sample:osc.value() equals:1.0];
  [self sample:osc.getNextValue() equals:1.0];
  [self sample:osc.getNextValue() equals:0.5];
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:-0.5];
  [self sample:osc.getNextValue() equals:-1.0];
  [self sample:osc.getNextValue() equals:-0.5];
  [self sample:osc.getNextValue() equals:0.0];
}

- (void)testDelay {
  auto osc = LFOTestInjector::make(8.0, 1.0, 0.125);
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.5];
  osc = LFOTestInjector::make(8.0, 1.0, 0.25);
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.5];
}

- (void)testConfig {
  auto osc = LFOTestInjector::make(8.0, 1.0, 0.125);
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.5];
  osc = LFOTestInjector::make(8.0, 1.0, 0.0);
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.5];
  osc = LFOTestInjector::make(8.0, 2.0, 0.0);
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:1.0];
  osc = LFOTestInjector::make(8.0, 1.0, 0.0);
  [self sample:osc.getNextValue() equals:0.0];
  [self sample:osc.getNextValue() equals:0.5];
  [self sample:osc.getNextValue() equals:1.0];
}

@end
