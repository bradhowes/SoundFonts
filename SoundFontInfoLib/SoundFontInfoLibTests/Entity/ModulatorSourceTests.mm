// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Modulator/Source.hpp"

using namespace SF2::Entity::Modulator;

@interface EntityModulatorSourceTests : XCTestCase
@end

@implementation EntityModulatorSourceTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testValidity {
  Source s(0);
  XCTAssertTrue(s.isValid());
  XCTAssertTrue(s.isUnipolar());
  XCTAssertTrue(s.isMinToMax());
  XCTAssertEqual(Source::ContinuityType::linear, s.type());
  XCTAssertEqual("linear", s.continuityTypeName());
  
  XCTAssertFalse(s.isContinuousController());
  XCTAssertFalse(s.isBipolar());
  XCTAssertFalse(s.isMaxToMin());
}

- (void)testLinear {
  Source s(0 << 10);
  XCTAssertTrue(s.isValid());
  XCTAssertTrue(s.isUnipolar());
  XCTAssertTrue(s.isMinToMax());
  XCTAssertEqual(Source::ContinuityType::linear, s.type());
  XCTAssertEqual("linear", s.continuityTypeName());
}

- (void)testConcave {
  Source s(1 << 10);
  XCTAssertTrue(s.isValid());
  XCTAssertTrue(s.isUnipolar());
  XCTAssertTrue(s.isMinToMax());
  XCTAssertEqual(Source::ContinuityType::concave, s.type());
  XCTAssertEqual("concave", s.continuityTypeName());
}

- (void)testConvex {
  Source s(2 << 10);
  XCTAssertTrue(s.isValid());
  XCTAssertTrue(s.isUnipolar());
  XCTAssertTrue(s.isMinToMax());
  XCTAssertEqual(Source::ContinuityType::convex, s.type());
  XCTAssertEqual("convex", s.continuityTypeName());
}

- (void)testSwitched {
  Source s(3 << 10);
  XCTAssertTrue(s.isValid());
  XCTAssertTrue(s.isUnipolar());
  XCTAssertTrue(s.isMinToMax());
  XCTAssertEqual(Source::ContinuityType::switched, s.type());
  XCTAssertEqual("switched", s.continuityTypeName());
}

- (void)testGeneralIndices {
  for (auto bits : {0, 2, 3, 10, 13, 14, 16, 127}) {
    Source s(bits);
    XCTAssertTrue(s.isValid());
    XCTAssertFalse(s.isContinuousController());
    XCTAssertEqual(Source::GeneralIndex(bits), s.generalIndex());
  }
  
  for (auto bits : {1, 4, 5, 11, 126}) {
    Source s(bits);
    XCTAssertFalse(s.isValid());
    XCTAssertFalse(s.isContinuousController());
  }
}

- (void)testContinuousIndices {
  for (auto bits : {1, 2, 3, 4, 31, 64, 97, 119}) {
    Source s(bits | (1 << 7));
    XCTAssertTrue(s.isValid());
    XCTAssertTrue(s.isContinuousController());
    XCTAssertEqual(bits, s.continuousIndex());
  }
  
  for (auto bits : {0, 6, 32, 63, 98, 101, 120, 127}) {
    Source s(bits | (1 << 7));
    XCTAssertFalse(s.isValid());
    XCTAssertTrue(s.isContinuousController());
  }
}

- (void)testDirection {
  Source s(0);
  XCTAssertTrue(s.isMinToMax());
  XCTAssertFalse(s.isMaxToMin());
  s = Source(1 << 8);
  XCTAssertFalse(s.isMinToMax());
  XCTAssertTrue(s.isMaxToMin());
}


- (void)testPolarity {
  Source s(0);
  XCTAssertTrue(s.isUnipolar());
  XCTAssertFalse(s.isBipolar());
  s = Source(1 << 9);
  XCTAssertFalse(s.isUnipolar());
  XCTAssertTrue(s.isBipolar());
}

- (void)testBuilderBasic {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertTrue(s0.isMinToMax());
  XCTAssertTrue(s0.isUnipolar());
  XCTAssertEqual(s0.type(), Source::ContinuityType::linear);
}

- (void)testBuilderNone {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::none)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::none);
  XCTAssertTrue(s0.isNone());
}

- (void)testBuilderGeneralPositiveUnipolarLinear {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .positive()
      .unipolar()
    .continuity(Source::ContinuityType::linear)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertTrue(s0.isMinToMax());
  XCTAssertTrue(s0.isUnipolar());
  XCTAssertEqual(s0.type(), Source::ContinuityType::linear);
}

- (void)testBuilderGeneralNegativeUnipolarLinear {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .negative()
      .unipolar()
    .continuity(Source::ContinuityType::linear)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertTrue(s0.isMaxToMin());
  XCTAssertTrue(s0.isUnipolar());
  XCTAssertEqual(s0.type(), Source::ContinuityType::linear);
}

- (void)testBuilderGeneralPositiveBipolarLinear {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .negative()
      .bipolar()
    .continuity(Source::ContinuityType::linear)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertTrue(s0.isMaxToMin());
  XCTAssertTrue(s0.isBipolar());
  XCTAssertEqual(s0.type(), Source::ContinuityType::linear);
}

- (void)testBuilderGeneralPositiveBipolarConcave {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .negative()
      .bipolar()
    .continuity(Source::ContinuityType::concave)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertTrue(s0.isMaxToMin());
  XCTAssertTrue(s0.isBipolar());
  XCTAssertEqual(s0.type(), Source::ContinuityType::concave);
}

- (void)testBuilderGeneralPositiveBipolarConvex {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .negative()
      .bipolar()
    .continuity(Source::ContinuityType::convex)};
  XCTAssertEqual(s0.generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertTrue(s0.isMaxToMin());
  XCTAssertTrue(s0.isBipolar());
  XCTAssertEqual(s0.type(), Source::ContinuityType::convex);
}

- (void)testFlippingDirection {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .positive()
      .negative()
      .positive()
    .continuity(Source::ContinuityType::convex)};
  XCTAssertTrue(s0.isMinToMax());
}

- (void)testFlippingPolarity {
  Source s0{Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
      .unipolar()
      .bipolar()
      .unipolar()
    .continuity(Source::ContinuityType::convex)};
  XCTAssertTrue(s0.isUnipolar());
}

- (void)testChangingContinuity {
  Source::Builder builder = Source::Builder::GeneralController(Source::GeneralIndex::noteOnVelocity)
    .continuity(Source::ContinuityType::linear)
    .continuity(Source::ContinuityType::switched);
  XCTAssertEqual(Source{builder}.type(), Source::ContinuityType::switched);
  builder = builder.continuity(Source::ContinuityType::linear);
  XCTAssertEqual(Source{builder}.type(), Source::ContinuityType::linear);
}

@end
