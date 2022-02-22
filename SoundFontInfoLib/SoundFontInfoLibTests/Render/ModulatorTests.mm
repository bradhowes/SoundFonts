// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import "SampleBasedContexts.hpp"

#import "Entity/Generator/Index.hpp"
#import "Entity/Modulator/Modulator.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Modulator.hpp"
#import "Render/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Entity::Generator;

@interface ModulatorTests : XCTestCase {
  MIDI::Channel* channel;
  State* state;
};
@end

@implementation ModulatorTests

- (void)setUp {
  channel = new MIDI::Channel();
  state = new State(44100.0, *channel);
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
  [self sample:modulator.value() equals:0.0];

  state->setPrincipleValue(Index::forcedMIDIVelocity, 64);
  [self sample: modulator.value() equals:119.049498789];

  state->setPrincipleValue(Index::forcedMIDIVelocity, 1);
  [self sample: modulator.value() equals:841.521488382];
}

- (void)testKeyVelocityToFilterCutoff {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[1]};
  state->setPrincipleValue(Index::forcedMIDIVelocity, -1);

  Modulator modulator{0, config, *state};
  state->setPrincipleValue(Index::forcedMIDIVelocity, 127);
  [self sample:modulator.value() equals:-18.75];

  state->setPrincipleValue(Index::forcedMIDIVelocity, 64);
  [self sample: modulator.value() equals:-1200.0];

  state->setPrincipleValue(Index::forcedMIDIVelocity, 1);
  [self sample: modulator.value() equals:config.amount() * 127.0 / 128.0];
}

- (void)testChannelPressureToVibratoLFOPitchDepth {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[2]};
  Modulator modulator{0, config, *state};
  channel->setChannelPressure(0);
  [self sample: modulator.value() equals:0.0];

  channel->setChannelPressure(64);
  [self sample: modulator.value() equals:25.0];

  channel->setChannelPressure(127);
  [self sample: modulator.value() equals:config.amount() * 127.0 / 128.0];
}

- (void)testCC1ToVibratoLFOPitchDepth {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[3]};
  XCTAssertEqual(1, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(1, 0);
  [self sample: modulator.value() equals:0.0];

  channel->setContinuousControllerValue(1, 64);
  [self sample: modulator.value() equals:25.0];

  channel->setContinuousControllerValue(1, 127);
  [self sample: modulator.value() equals:config.amount() * 127.0 / 128.0];
}

- (void)testCC7ToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[4]};
  XCTAssertEqual(7, config.source().continuousIndex());

  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(7, 0);
  [self sample: modulator.value() equals:960.0];

  channel->setContinuousControllerValue(7, 64);
  [self sample: modulator.value() equals:119.049498789];

  channel->setContinuousControllerValue(7, 127);
  [self sample: modulator.value() equals:0.0];
}

- (void)testCC10ToPanPosition {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[5]};
  XCTAssertEqual(10, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(10, 0);
  [self sample: modulator.value() equals:-1000];

  channel->setContinuousControllerValue(10, 64);
  [self sample: modulator.value() equals:0];

  channel->setContinuousControllerValue(10, 127);
  [self sample: modulator.value() equals:config.amount() * DSP::unipolarToBipolar(127.0 / 128.0)];
}

- (void)testCC11ToInitialAttenuation {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[6]};
  XCTAssertEqual(11, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(11, 0);
  [self sample: modulator.value() equals:960.0];

  channel->setContinuousControllerValue(11, 64);
  [self sample: modulator.value() equals:119.049498789];

  channel->setContinuousControllerValue(11, 127);
  [self sample: modulator.value() equals:0.0];
}

- (void)testCC91ToReverbSend {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[7]};
  XCTAssertEqual(91, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(91, 0);
  [self sample: modulator.value() equals:0.0];

  channel->setContinuousControllerValue(91, 64);
  [self sample: modulator.value() equals:100.0];

  channel->setContinuousControllerValue(91, 127);
  [self sample: modulator.value() equals:config.amount() * 127.0 / 128.0];
}

- (void)testCC93ToChorusSend {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[8]};
  XCTAssertEqual(93, config.source().continuousIndex());
  Modulator modulator{0, config, *state};

  channel->setContinuousControllerValue(93, 0);
  [self sample: modulator.value() equals:0.0];

  channel->setContinuousControllerValue(93, 64);
  [self sample: modulator.value() equals:100.0];

  channel->setContinuousControllerValue(93, 127);
  [self sample: modulator.value() equals:config.amount() * 127.0 / 128.0];
}

- (void)testPitchWheelToInitialPitch {
  const Entity::Modulator::Modulator& config{Entity::Modulator::Modulator::defaults[9]};
  XCTAssertEqual(Entity::Modulator::Source::GeneralIndex::pitchWheel, config.source().generalIndex());
  Modulator modulator{0, config, *state};

  channel->setPitchWheelSensitivity(0);

  channel->setPitchWheelValue(0);
  [self sample: modulator.value() equals:0.0];

  channel->setPitchWheelValue(64);
  [self sample: modulator.value() equals:0.0];

  channel->setPitchWheelValue(127);
  [self sample: modulator.value() equals:0.0];

  channel->setPitchWheelSensitivity(127);

  channel->setPitchWheelValue(0);
  [self sample: modulator.value() equals:-12600.78125];

  channel->setPitchWheelValue(64);
  [self sample: modulator.value() equals:0.0];

  channel->setPitchWheelValue(127);
  [self sample: modulator.value() equals:12403.89404296875];
}

@end
