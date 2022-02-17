// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import "SampleBasedTestCase.h"

#import "Entity/Generator/Index.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "Render/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Entity::Generator;

@interface StateTests : SampleBasedTestCase
@end

@implementation StateTests

- (void)testInit {
  State state{context3.makeState(69, 64)};
  XCTAssertEqual(0, state.unmodulated(Index::startAddressOffset));
  XCTAssertEqual(0, state.unmodulated(Index::endAddressOffset));
  XCTAssertEqual(9023, state.unmodulated(Index::initialFilterCutoff));
  XCTAssertEqual(-12000, state.unmodulated(Index::delayModulatorLFO));
  XCTAssertEqual(-12000, state.unmodulated(Index::delayVibratoLFO));
  XCTAssertEqual(-12000, state.unmodulated(Index::attackModulatorEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::holdModulatorEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::decayModulatorEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::releaseModulatorEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::delayVolumeEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::attackVolumeEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::holdVolumeEnvelope));
  XCTAssertEqual(-12000, state.unmodulated(Index::decayVolumeEnvelope));
  XCTAssertEqual(2041, state.unmodulated(Index::releaseVolumeEnvelope));
  XCTAssertEqual(-1, state.unmodulated(Index::forcedMIDIKey));
  XCTAssertEqual(-1, state.unmodulated(Index::forcedMIDIVelocity));
  XCTAssertEqual(100, state.unmodulated(Index::scaleTuning));
  XCTAssertEqual(-1, state.unmodulated(Index::overridingRootKey));
}

- (void)testKey {
  State state{context3.makeState(64, 32)};
  XCTAssertEqual(64, state.eventKey());
  XCTAssertEqual(64, state.key());
  state.setPrincipleValue(Index::forcedMIDIKey, 128);
  XCTAssertEqual(64, state.eventKey());
  XCTAssertEqual(128, state.key());
}

- (void)testVelocity {
  State state{context3.makeState(64, 32)};
  XCTAssertEqual(32, state.eventVelocity());
  XCTAssertEqual(32, state.velocity());
  state.setPrincipleValue(Index::forcedMIDIVelocity, 128);
  XCTAssertEqual(32, state.eventVelocity());
  XCTAssertEqual(128, state.velocity());
}

- (void)testEnvelopeSustainLevel {
  double epsilon = 0.000001;
  State state{context3.makeState(64, 32)};
  state.setPrincipleValue(Index::sustainVolumeEnvelope, 0);
  XCTAssertEqualWithAccuracy(1.0, state.sustainLevelVolumeEnvelope(), epsilon);
  state.setPrincipleValue(Index::sustainVolumeEnvelope, 100);
  XCTAssertEqualWithAccuracy(0.9, state.sustainLevelVolumeEnvelope(), epsilon);
  state.setPrincipleValue(Index::sustainVolumeEnvelope, 500);
  XCTAssertEqualWithAccuracy(0.5, state.sustainLevelVolumeEnvelope(), epsilon);
  state.setPrincipleValue(Index::sustainVolumeEnvelope, 900);
  XCTAssertEqualWithAccuracy(0.1, state.sustainLevelVolumeEnvelope(), epsilon);
}

- (void)testModulatedValue {
  State state{context3.makeState(60, 32)};
  state.setPrincipleValue(Index::holdVolumeEnvelope, 100);
  state.setAdjustmentValue(Index::holdVolumeEnvelope, 0);
  XCTAssertEqualWithAccuracy(100.0, state.modulated(Index::holdVolumeEnvelope), 0.000001);
  state.setAdjustmentValue(Index::holdVolumeEnvelope, 50);
  XCTAssertEqualWithAccuracy(150.0, state.modulated(Index::holdVolumeEnvelope), 0.000001);
}

- (void)testKeyedEnvelopeModulator {
  State state{context3.makeState(60, 32)};

  // 1s hold duration
  state.setPrincipleValue(Index::holdVolumeEnvelope, 0);
  // Track keyboard such that octave increase results in 0.5 x hold duration
  state.setPrincipleValue(Index::midiKeyToVolumeEnvelopeHold, 100);
  // For key 60 there is no scaling so no adjustment to hold duration
  state.setPrincipleValue(Index::forcedMIDIKey, 60);
  XCTAssertEqualWithAccuracy(0.0, state.keyedVolumeEnvelopeHold(), 0.000001);
  XCTAssertEqualWithAccuracy(1.0, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                      state.keyedVolumeEnvelopeHold()), 0.001);

  // An octave increase should halve the duration.
  state.setPrincipleValue(Index::forcedMIDIKey, 72);
  XCTAssertEqualWithAccuracy(-1200.0, state.keyedVolumeEnvelopeHold(), 0.000001);
  XCTAssertEqualWithAccuracy(0.5, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                      state.keyedVolumeEnvelopeHold()), 0.001);

  // An octave decrease should double the duration.
  state.setPrincipleValue(Index::forcedMIDIKey, 48);
  XCTAssertEqualWithAccuracy(1200.0, state.keyedVolumeEnvelopeHold(), 0.000001);
  XCTAssertEqualWithAccuracy(2.0, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                      state.keyedVolumeEnvelopeHold()), 0.001);

  // Validate spec scenario
  state.setPrincipleValue(Index::forcedMIDIKey, 36);
  state.setPrincipleValue(Index::midiKeyToVolumeEnvelopeHold, 50);
  state.setPrincipleValue(Index::holdVolumeEnvelope, -7973);
  XCTAssertEqualWithAccuracy(1200.0, state.keyedVolumeEnvelopeHold(), 0.000001);
  XCTAssertEqualWithAccuracy(0.02, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                       state.keyedVolumeEnvelopeHold()), 0.001);
}

- (void)testLoopingModes {
  State state{context3.makeState(60, 32)};
  XCTAssertEqual(State::LoopingMode::none, state.loopingMode());
  state.setPrincipleValue(Index::sampleModes, -1);
  XCTAssertEqual(State::LoopingMode::none, state.loopingMode());
  state.setPrincipleValue(Index::sampleModes, 1);
  XCTAssertEqual(State::LoopingMode::activeEnvelope, state.loopingMode());
  state.setPrincipleValue(Index::sampleModes, 2);
  XCTAssertEqual(State::LoopingMode::none, state.loopingMode());
  state.setPrincipleValue(Index::sampleModes, 3);
  XCTAssertEqual(State::LoopingMode::duringKeyPress, state.loopingMode());
  state.setPrincipleValue(Index::sampleModes, 4);
  XCTAssertEqual(State::LoopingMode::none, state.loopingMode());
}

@end
