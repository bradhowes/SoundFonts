// Copyright © 2021 Brad Howes. All rights reserved.

#include <iostream>

#include <XCTest/XCTest.h>

#include "Entity/Modulator/Modulator.hpp"

using namespace SF2::Entity::Modulator;

@interface ModulatorDefaultsTests : XCTestCase
@end

@implementation ModulatorDefaultsTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testNoteOnVelocityToInitialAttenuation { // 8.4.1
  auto mod = Modulator::defaults[0];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::concave);
  XCTAssertTrue(mod.source().isMaxToMin());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertEqual(mod.amount(), 960);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testNoteOnVelocityToFilterCutoff { // 8.4.2
  auto mod = Modulator::defaults[1];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMaxToMin());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().generalIndex(), Source::GeneralIndex::noteOnVelocity);
  XCTAssertEqual(mod.amount(), -2400);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testChannelPressureToVibratoLFOPitchDepth { // 8.4.3
  auto mod = Modulator::defaults[2];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMinToMax());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().generalIndex(), Source::GeneralIndex::channelPressure);
  XCTAssertEqual(mod.amount(), 50);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testCC1ToVibratoLFOPitchDepth { // 8.4.4
  auto mod = Modulator::defaults[3];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMinToMax());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().continuousIndex(), 1);
  XCTAssertEqual(mod.amount(), 50);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testCC7ToInitialAttenuation { // 8.4.5
  auto mod = Modulator::defaults[4];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::concave);
  XCTAssertTrue(mod.source().isMaxToMin());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().continuousIndex(), 7);
  XCTAssertEqual(mod.amount(), 960);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testCC10ToPanPosition { // 8.4.6
  auto mod = Modulator::defaults[5];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMinToMax());
  XCTAssertTrue(mod.source().isBipolar());
  XCTAssertEqual(mod.source().continuousIndex(), 10);
  XCTAssertEqual(mod.amount(), 1000);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testCC11ToInitialAttenuation { // 8.4.7
  auto mod = Modulator::defaults[6];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::concave);
  XCTAssertTrue(mod.source().isMaxToMin());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().continuousIndex(), 11);
  XCTAssertEqual(mod.amount(), 960);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testCC91ToReverbEffectsSend { // 8.4.8
  auto mod = Modulator::defaults[7];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMinToMax());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().continuousIndex(), 91);
  XCTAssertEqual(mod.amount(), 200);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testCC93ToChorusEffectsSend { // 8.4.9
  auto mod = Modulator::defaults[8];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMinToMax());
  XCTAssertTrue(mod.source().isUnipolar());
  XCTAssertEqual(mod.source().continuousIndex(), 93);
  XCTAssertEqual(mod.amount(), 200);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::none);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

- (void)testPitchWheelToInitialPitch { // 8.4.10
  auto mod = Modulator::defaults[9];
  XCTAssertEqual(mod.source().type(), Source::ContinuityType::linear);
  XCTAssertTrue(mod.source().isMinToMax());
  XCTAssertTrue(mod.source().isBipolar());
  XCTAssertEqual(mod.source().generalIndex(), Source::GeneralIndex::pitchWheel);
  XCTAssertEqual(mod.amount(), 12700);
  XCTAssertEqual(mod.amountSource().generalIndex(), Source::GeneralIndex::pitchWheelSensitivity);
  XCTAssertEqual(mod.transform().kind(), Transform::Kind::linear);
}

@end
