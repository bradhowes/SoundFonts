// Copyright © 2020 Brad Howes. All rights reserved.

#include <XCTest/XCTest.h>

#include "Types.hpp"
#include "DSP/DSP.hpp"
#include "Render/Envelope/Generator.hpp"
#include "Render/Envelope/Stage.hpp"
#include "Render/Voice/State/State.hpp"

#include "SampleBasedContexts.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Render::Voice;
using namespace SF2::Render::Envelope;

namespace SF2::Render::Envelope {
struct EnvelopeTestInjector {
  static Generator make(Float sampleRate, Float delay, Float attack, Float hold, Float decay, Float sustain, Float release) {
    return Generator(sampleRate, delay, attack, hold, decay, sustain, release);
  }
};
}

@interface EnvelopeTests : XCTestCase
@end

@implementation EnvelopeTests {
  SampleBasedContexts contexts;
}

- (void)testGateOnOff {
  auto gen = Generator();
  XCTAssertEqual(0.0, gen.value());
  XCTAssertEqual(StageIndex::idle, gen.stage());
  XCTAssertEqual(0.0, gen.getNextValue());
  XCTAssertEqual(StageIndex::idle, gen.stage());
  XCTAssertTrue(!gen.isGated());
  gen.gate(true);
  XCTAssertTrue(gen.isGated());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
  XCTAssertEqual(0.0, gen.getNextValue());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
  XCTAssertTrue(gen.isGated());
  gen.gate(false);
  XCTAssertTrue(!gen.isGated());
  XCTAssertEqual(StageIndex::idle, gen.stage());
}

- (void)testDelay {
  auto gen = EnvelopeTestInjector::make(1.0, 3, 0, 0, 0, 1, 0);
  XCTAssertEqual(0.0, gen.value());
  XCTAssertEqual(StageIndex::idle, gen.stage());
  XCTAssertEqual(0.0, gen.getNextValue());
  gen.gate(true);
  XCTAssertEqual(StageIndex::delay, gen.stage());
  XCTAssertEqual(0.0, gen.getNextValue());
  XCTAssertEqual(0.0, gen.getNextValue());
  XCTAssertEqual(1.0, gen.getNextValue());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
}

- (void)testNoDelayNoAttack {
  auto gen = EnvelopeTestInjector::make(1.0, 0, 0, 1, 0, 1, 0);
  gen.gate(true);
  XCTAssertEqual(StageIndex::hold, gen.stage());
  XCTAssertEqual(1.0, gen.getNextValue());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
}

- (void)testAttackCurvature {
  auto epsilon = 0.001;
  auto gen = EnvelopeTestInjector::make(1.0, 0, 10, 0, 0, 1, 0);
  gen.gate(true);
  XCTAssertEqual(0.0, gen.value());
  XCTAssertEqual(StageIndex::attack, gen.stage());
  XCTAssertEqualWithAccuracy(0.373366868371, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.60871114427, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.757055662464, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.850561637888, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.909501243789, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.946652635751, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.970070266453, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.98483109771, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.994135290015, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(1.0, gen.getNextValue(), epsilon);
}

- (void)testHold {
  auto gen = EnvelopeTestInjector::make(1.0, 0, 0, 3, 0, 0.75, 0);
  gen.gate(true);
  XCTAssertEqual(1.0, gen.value());
  XCTAssertEqual(StageIndex::hold, gen.stage());
  XCTAssertEqual(1.0, gen.getNextValue());
  XCTAssertEqual(1.0, gen.getNextValue());
  XCTAssertEqual(0.75, gen.getNextValue());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
}

- (void)testDecay {
  auto epsilon = 0.001;
  auto gen = EnvelopeTestInjector::make(1.0, 0, 0, 0, 5, 0.5, 0);
  gen.gate(true);
  XCTAssertEqual(StageIndex::decay, gen.stage());
  XCTAssertEqualWithAccuracy(0.692631006359, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.570508479878, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.521987282938, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.502709049671, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.500, gen.getNextValue(), epsilon);
  XCTAssertEqual(StageIndex::sustain, gen.stage());
  gen.gate(false);
  XCTAssertEqual(StageIndex::idle, gen.stage());
}

- (void)testDecayAborted {
  auto epsilon = 0.001;
  auto gen = EnvelopeTestInjector::make(1.0, 0, 0, 0, 5, 0.5, 0);
  gen.gate(true);
  XCTAssertEqual(StageIndex::decay, gen.stage());
  XCTAssertEqualWithAccuracy(0.692631006359, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.570508479878, gen.getNextValue(), epsilon);
  gen.gate(false);
  XCTAssertEqual(StageIndex::idle, gen.stage());
  XCTAssertEqualWithAccuracy(0.0, gen.getNextValue(), epsilon);
}

- (void)testSustain {
  auto gen = EnvelopeTestInjector::make(1.0, 0, 0, 0, 0, 0.25, 0);
  gen.gate(true);
  XCTAssertEqual(0.25, gen.value());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
  XCTAssertEqual(0.25, gen.getNextValue());
  XCTAssertEqual(0.25, gen.getNextValue());
  gen.gate(false);
  XCTAssertEqual(StageIndex::idle, gen.stage());
}

- (void)testRelease {
  auto epsilon = 0.001;
  auto gen = EnvelopeTestInjector::make(1.0, 0, 0, 0, 0, 0.5, 5);
  gen.gate(true);
  XCTAssertEqual(0.5, gen.value());
  XCTAssertEqual(StageIndex::sustain, gen.stage());
  gen.gate(false);
  XCTAssertEqual(StageIndex::release, gen.stage());
  XCTAssertEqualWithAccuracy(0.192631006359, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.0705084798785, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.0219872829376, gen.getNextValue(), epsilon);
  XCTAssertEqualWithAccuracy(0.00270904967126, gen.getNextValue(), epsilon);
  XCTAssertEqual(StageIndex::release, gen.stage());
  XCTAssertEqualWithAccuracy(0.000, gen.getNextValue(), epsilon);
  XCTAssertEqual(StageIndex::idle, gen.stage());
}

- (void)testEnvelopeSustainLevel {
  Float epsilon = 0.000001;
  State::State state{contexts.context3.makeState(64, 32)};

  state.setValue(State::State::Index::sustainVolumeEnvelope, 0);
  XCTAssertEqualWithAccuracy(1.0, Generator::forVol(state)[StageIndex::sustain].initial(), epsilon);

  state.setValue(State::State::Index::sustainVolumeEnvelope, 100);
  XCTAssertEqualWithAccuracy(0.9, Generator::forVol(state)[StageIndex::sustain].initial(), epsilon);

  state.setValue(State::State::Index::sustainVolumeEnvelope, 500);
  XCTAssertEqualWithAccuracy(0.5, Generator::forVol(state)[StageIndex::sustain].initial(), epsilon);

  state.setValue(State::State::Index::sustainVolumeEnvelope, 900);
  XCTAssertEqualWithAccuracy(0.1, Generator::forVol(state)[StageIndex::sustain].initial(), epsilon);
}

- (void)testKeyToMod {
  Float epsilon = 0.000001;
  auto s1 = contexts.context3.makeState(60, 32);
  
  // 1s hold duration
  s1.setValue(State::State::Index::holdVolumeEnvelope, 0);
  // Track keyboard such that octave increase results in 0.5 x hold duration
  s1.setValue(State::State::Index::midiKeyToVolumeEnvelopeHold, 100);
  // For key 60 there is no scaling so no adjustment to hold duration
  auto duration = Generator::forVol(s1)[StageIndex::hold].duration();
  XCTAssertEqualWithAccuracy(s1.sampleRate(), duration, epsilon);

  // An octave increase should halve the duration.
  auto s2 = contexts.context3.makeState(72, 32);
  s2.setValue(State::State::Index::holdVolumeEnvelope, 0);
  s2.setValue(State::State::Index::midiKeyToVolumeEnvelopeHold, 100);
  duration = Generator::forVol(s2)[StageIndex::hold].duration();
  XCTAssertEqualWithAccuracy(s2.sampleRate() / 2.0, duration, epsilon);

  // An octave decrease should double the duration.
  auto s3 = contexts.context3.makeState(48, 32);
  s3.setValue(State::State::Index::holdVolumeEnvelope, 0);
  s3.setValue(State::State::Index::midiKeyToVolumeEnvelopeHold, 100);
  duration = Generator::forVol(s3)[StageIndex::hold].duration();
  XCTAssertEqualWithAccuracy(s3.sampleRate() * 2.0, duration, epsilon);

  // Validate spec scenario
  auto s4 = contexts.context3.makeState(36, 32);
  s4.setValue(State::State::Index::midiKeyToVolumeEnvelopeHold, 50);
  s4.setValue(State::State::Index::holdVolumeEnvelope, -7973);
  duration = Generator::forVol(s4)[StageIndex::hold].duration();
  XCTAssertEqualWithAccuracy(882, duration, 0.000001);
}

@end
