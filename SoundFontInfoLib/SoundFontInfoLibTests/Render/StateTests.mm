// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import "SampleBasedContexts.hpp"

#import "Entity/Generator/Index.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "Render/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Entity::Generator;

@interface StateTests : XCTestCase
@end

@implementation StateTests {
  SampleBasedContexts contexts;
}

- (void)testInit {
  State state{contexts.context3.makeState(69, 64)};
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
  State state{contexts.context3.makeState(64, 32)};
  XCTAssertEqual(64, state.key());
  state.setValue(Index::forcedMIDIKey, 128);
  XCTAssertEqual(128, state.key());
}

- (void)testVelocity {
  State state{contexts.context3.makeState(64, 32)};
  XCTAssertEqual(32, state.velocity());
  state.setValue(Index::forcedMIDIVelocity, 128);
  XCTAssertEqual(128, state.velocity());
}

- (void)testModulatedValue {
  State state{contexts.context3.makeState(60, 32)};
  state.setValue(Index::holdVolumeEnvelope, 100);
  state.setAdjustment(Index::holdVolumeEnvelope, 0);
  XCTAssertEqualWithAccuracy(100.0, state.modulated(Index::holdVolumeEnvelope), 0.000001);
  state.setAdjustment(Index::holdVolumeEnvelope, 50);
  XCTAssertEqualWithAccuracy(150.0, state.modulated(Index::holdVolumeEnvelope), 0.000001);
}

@end
