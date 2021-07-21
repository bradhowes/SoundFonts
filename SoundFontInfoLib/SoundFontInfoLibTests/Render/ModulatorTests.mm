// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#import "Entity/Generator/Index.hpp"
#import "Entity/Modulator/Modulator.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Modulator.hpp"
#import "Render/Voice/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Entity::Generator;

@interface ModulatorTests : XCTestCase {
  MIDI::Channel* channel;
  Voice::State* state;
};
@end

@implementation ModulatorTests

- (void)setUp {
  channel = new MIDI::Channel();
  state = new Voice::State(44100.0, *channel, 64, 64);
}

- (void)tearDown {
  delete state;
  delete channel;
}

- (void)testKeyVelocityToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[0]};
  state->setPrincipleValue(Index::forcedMIDIVelocity, -1);

  Modulator modulator{0, config, *state};
  state->setPrincipleValue(Index::forcedMIDIVelocity, 127);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  state->setPrincipleValue(Index::forcedMIDIVelocity, 64);
  XCTAssertEqualWithAccuracy(119.049498789, modulator.value(), 0.000001);

  state->setPrincipleValue(Index::forcedMIDIVelocity, 1);
  XCTAssertEqualWithAccuracy(841.521488382, modulator.value(), 0.000001);
}

- (void)testKeyVelocityToFilterCutoff {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[1]};
  state->setPrincipleValue(Index::forcedMIDIVelocity, -1);

  Modulator modulator{0, config, *state};
  state->setPrincipleValue(Index::forcedMIDIVelocity, 127);
  XCTAssertEqualWithAccuracy(-18.75, modulator.value(), 0.000001);

  state->setPrincipleValue(Index::forcedMIDIVelocity, 64);
  XCTAssertEqualWithAccuracy(-1200.0, modulator.value(), 0.000001);

  state->setPrincipleValue(Index::forcedMIDIVelocity, 1);
  XCTAssertEqualWithAccuracy(config.amount() * 127.0 / 128.0, modulator.value(), 0.000001);
}

- (void)testChannelPressureToVibratoLFOPitchDepth {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[2]};
  Modulator modulator{0, config, *state};
  channel->setChannelPressure(0);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setChannelPressure(64);
  XCTAssertEqualWithAccuracy(25.0, modulator.value(), 0.000001);

  channel->setChannelPressure(127);
  XCTAssertEqualWithAccuracy(config.amount() * 127.0 / 128.0, modulator.value(), 0.000001);
}

- (void)testCC1ToVibratoLFOPitchDepth {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[3]};
  XCTAssertEqual(1, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(1, 0);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(1, 64);
  XCTAssertEqualWithAccuracy(25.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(1, 127);
  XCTAssertEqualWithAccuracy(config.amount() * 127.0 / 128.0, modulator.value(), 0.000001);
}

- (void)testCC7ToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[4]};
  XCTAssertEqual(7, config.source().continuousIndex());

  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(7, 0);
  XCTAssertEqualWithAccuracy(960.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(7, 64);
  XCTAssertEqualWithAccuracy(119.049498789, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(7, 127);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);
}

- (void)testCC10ToPanPosition {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[5]};
  XCTAssertEqual(10, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(10, 0);
  XCTAssertEqualWithAccuracy(-1000, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(10, 64);
  XCTAssertEqualWithAccuracy(0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(10, 127);
  XCTAssertEqualWithAccuracy(config.amount() * DSP::unipolarToBipolar(127.0 / 128.0), modulator.value(), 0.000001);
}

- (void)testCC11ToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[6]};
  XCTAssertEqual(11, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(11, 0);
  XCTAssertEqualWithAccuracy(960.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(11, 64);
  XCTAssertEqualWithAccuracy(119.049498789, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(11, 127);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);
}

- (void)testCC91ToReverbSend {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[7]};
  XCTAssertEqual(91, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(91, 0);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(91, 64);
  XCTAssertEqualWithAccuracy(100.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(91, 127);
  XCTAssertEqualWithAccuracy(config.amount() * 127.0 / 128.0, modulator.value(), 0.000001);
}

- (void)testCC93ToChorusSend {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[8]};
  XCTAssertEqual(93, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(93, 0);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(93, 64);
  XCTAssertEqualWithAccuracy(100.0, modulator.value(), 0.000001);

  channel->setContinuousControllerValue(93, 127);
  XCTAssertEqualWithAccuracy(config.amount() * 127.0 / 128.0, modulator.value(), 0.000001);
}

- (void)testPitchWheelToInitialPitch {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[9]};
  XCTAssertEqual(Entity::Modulator::Source::GeneralIndex::pitchWheel, config.source().generalIndex());
  Modulator modulator{0, config, *state};

  channel->setPitchWheelSensitivity(0);

  channel->setPitchWheelValue(0);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setPitchWheelValue(64);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setPitchWheelValue(127);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setPitchWheelSensitivity(127);

  channel->setPitchWheelValue(0);
  XCTAssertEqualWithAccuracy(-12600.78125, modulator.value(), 0.000001);

  channel->setPitchWheelValue(64);
  XCTAssertEqualWithAccuracy(0.0, modulator.value(), 0.000001);

  channel->setPitchWheelValue(127);
  XCTAssertEqualWithAccuracy(12403.894043, modulator.value(), 0.000001);
}

@end
