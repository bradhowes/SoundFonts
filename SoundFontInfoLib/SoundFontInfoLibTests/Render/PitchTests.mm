// Copyright © 2020 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#import "Entity/SampleHeader.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Voice/Sample/Pitch.hpp"
#import "Render/Voice/State/State.hpp"

using namespace SF2;
using namespace SF2::Render::Voice;
using namespace SF2::Render::Voice::Sample;

@interface PitchTests : XCTestCase
@end

@implementation PitchTests {
  Float epsilon;
  MIDI::Channel channel;
}

- (void)setUp {
  epsilon = 1.0e-7f;
}

- (void)testUnity {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
}

- (void)test2x {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey + 12; // A5
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
}

- (void)test4x {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey + 24; // A6
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 4.0, epsilon);
}

- (void)testOverrideRoot {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};

  state.setValue(State::State::Index::overridingRootKey, 81);
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);
}

- (void)testGeneratorKey {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey + 12;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0);

  State::State state{44100.0, channel, eventKey};

  // NOTE: since the forceMIDIKey is not a real-time parameter, it is only read once when Pitch is created.
  state.setValue(State::State::Index::forcedMIDIKey, 69);
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
}

- (void)testDoubleSampleRate {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey;
  Entity::SampleHeader header(0, 100, 80, 90, 22050.0, sourceKey, 0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);
}

- (void)testPosPitchAdjustment {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey - 1;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 100.0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, 1.0e-3f);
}

- (void)testNegPitchAdjustment {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey + 1;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, -100.0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
}

- (void)testScaleTuning {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey + 1;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0.0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};

  // Make every key use the same frequency as the source key.
  state.setValue(State::State::Index::scaleTuning, 0.0);
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);

  // Make keys play octaves above/below the sourceKey.
  state.setValue(State::State::Index::scaleTuning, 1200.0);
  pitch.configure(header);

  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
}

- (void)testModLFOEffect {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0.0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);

  state.setValue(State::State::Index::modulatorLFOToPitch, 1200);
  inc = pitch.samplePhaseIncrement(1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
  inc = pitch.samplePhaseIncrement(-1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);

  state.setValue(State::State::Index::modulatorLFOToPitch, -1200);
  inc = pitch.samplePhaseIncrement(1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
  inc = pitch.samplePhaseIncrement(-1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
}

- (void)testVibLFOEffect {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0.0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);

  state.setValue(State::State::Index::vibratoLFOToPitch, 1200);
  inc = pitch.samplePhaseIncrement(0.0, 1.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, -1.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);

  state.setValue(State::State::Index::vibratoLFOToPitch, -1200);
  inc = pitch.samplePhaseIncrement(0.0, 1.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, -1.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
}

- (void)testModEnvEffect {
  auto sourceKey = 69; // A4
  auto eventKey = sourceKey;
  Entity::SampleHeader header(0, 100, 80, 90, 44100.0, sourceKey, 0.0);
  State::State state{44100.0, channel, eventKey};
  Pitch pitch{state};
  pitch.configure(header);

  auto inc = pitch.samplePhaseIncrement(1.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);

  state.setValue(State::State::Index::modulatorEnvelopeToPitch, 1200);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 1.0);
  XCTAssertEqualWithAccuracy(inc, 2.0, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);

  state.setValue(State::State::Index::modulatorEnvelopeToPitch, -1200);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 1.0);
  XCTAssertEqualWithAccuracy(inc, 0.5, epsilon);
  inc = pitch.samplePhaseIncrement(0.0, 0.0, 0.0);
  XCTAssertEqualWithAccuracy(inc, 1.0, epsilon);
}

@end
