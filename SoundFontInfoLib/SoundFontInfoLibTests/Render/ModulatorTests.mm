// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import "SampleBasedContexts.hpp"

#import "Entity/Generator/Index.hpp"
#import "Entity/Modulator/Modulator.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Voice/State/Modulator.hpp"
#import "Render/Voice/State/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Render::Voice;
using namespace SF2::Entity::Generator;

@interface ModulatorTests : XCTestCase {
  Float epsilon;
  MIDI::Channel* channel;
  State::State* state;
};
@end

@implementation ModulatorTests

- (void)setUp {
  epsilon = 1.0e-3f;
  channel = new MIDI::Channel();
  state = new State::State(44100.0, *channel);
}

- (void)tearDown {
  delete state;
  delete channel;
}

- (void)testKeyVelocityToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[0]};
  state->setValue(Index::forcedMIDIVelocity, -1);

  State::Modulator modulator{0, config, *state};
  state->setValue(Index::forcedMIDIVelocity, 127);
  XCTAssertEqualWithAccuracy(modulator.value(), 0.0, epsilon);

  state->setValue(Index::forcedMIDIVelocity, 64);
  XCTAssertEqualWithAccuracy(modulator.value(), 119.049498789, epsilon);

  state->setValue(Index::forcedMIDIVelocity, 1);
  XCTAssertEqualWithAccuracy( modulator.value(), 841.521488382, epsilon);
}

- (void)testKeyVelocityToFilterCutoff {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[1]};
  state->setValue(Index::forcedMIDIVelocity, -1);

  State::Modulator modulator{0, config, *state};
  state->setValue(Index::forcedMIDIVelocity, 127);
  XCTAssertEqualWithAccuracy(modulator.value(), -18.75, epsilon);

  state->setValue(Index::forcedMIDIVelocity, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), -1200.0, epsilon);

  state->setValue(Index::forcedMIDIVelocity, 1);
  XCTAssertEqualWithAccuracy( modulator.value(), config.amount() * 127.0 / 128.0, epsilon);
}

- (void)testChannelPressureToVibratoLFOPitchDepth {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[2]};
  State::Modulator modulator{0, config, *state};
  channel->setChannelPressure(0);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setChannelPressure(64);
  XCTAssertEqualWithAccuracy( modulator.value(), 25.0, epsilon);

  channel->setChannelPressure(127);
  XCTAssertEqualWithAccuracy( modulator.value(), config.amount() * 127.0 / 128.0, epsilon);
}

- (void)testCC1ToVibratoLFOPitchDepth {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[3]};
  XCTAssertEqual(1, config.source().continuousIndex());
  State::Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(1, 0);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setContinuousControllerValue(1, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), 25.0, epsilon);

  channel->setContinuousControllerValue(1, 127);
  XCTAssertEqualWithAccuracy( modulator.value(), config.amount() * 127.0 / 128.0, epsilon);
}

- (void)testCC7ToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[4]};
  XCTAssertEqual(7, config.source().continuousIndex());

  State::Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(7, 0);
  XCTAssertEqualWithAccuracy( modulator.value(), 960.0, epsilon);

  channel->setContinuousControllerValue(7, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), 119.049498789, epsilon);

  channel->setContinuousControllerValue(7, 127);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);
}

- (void)testCC10ToPanPosition {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[5]};
  XCTAssertEqual(10, config.source().continuousIndex());
  State::Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(10, 0);
  XCTAssertEqualWithAccuracy( modulator.value(), -1000, epsilon);

  channel->setContinuousControllerValue(10, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), 0, epsilon);

  channel->setContinuousControllerValue(10, 127);
  XCTAssertEqualWithAccuracy( modulator.value(), config.amount() * DSP::unipolarToBipolar(127.0 / 128.0), epsilon);
}

- (void)testCC11ToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[6]};
  XCTAssertEqual(11, config.source().continuousIndex());
  State::Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(11, 0);
  XCTAssertEqualWithAccuracy( modulator.value(), 960.0, epsilon);

  channel->setContinuousControllerValue(11, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), 119.049498789, epsilon);

  channel->setContinuousControllerValue(11, 127);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);
}

- (void)testCC91ToReverbSend {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[7]};
  XCTAssertEqual(91, config.source().continuousIndex());
  State::Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(91, 0);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setContinuousControllerValue(91, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), 100.0, epsilon);

  channel->setContinuousControllerValue(91, 127);
  XCTAssertEqualWithAccuracy( modulator.value(), config.amount() * 127.0 / 128.0, epsilon);
}

- (void)testCC93ToChorusSend {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[8]};
  XCTAssertEqual(93, config.source().continuousIndex());
  State:: Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(93, 0);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setContinuousControllerValue(93, 64);
  XCTAssertEqualWithAccuracy( modulator.value(), 100.0, epsilon);

  channel->setContinuousControllerValue(93, 127);
  XCTAssertEqualWithAccuracy( modulator.value(), config.amount() * 127.0 / 128.0, epsilon);
}

- (void)testPitchWheelToInitialPitch {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[9]};
  XCTAssertEqual(Entity::Modulator::Source::GeneralIndex::pitchWheel, config.source().generalIndex());
  State::Modulator modulator{0, config, *state};

  channel->setPitchWheelSensitivity(0);

  channel->setPitchWheelValue(0);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setPitchWheelValue(64);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setPitchWheelValue(127);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setPitchWheelSensitivity(127);

  channel->setPitchWheelValue(0);
  XCTAssertEqualWithAccuracy( modulator.value(), -12600.78125, epsilon);

  channel->setPitchWheelValue(64);
  XCTAssertEqualWithAccuracy( modulator.value(), 0.0, epsilon);

  channel->setPitchWheelValue(127);
  XCTAssertEqualWithAccuracy( modulator.value(), 12403.89404296875, epsilon);
}

@end
