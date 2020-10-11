// Copyright © 2020 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#include "Render/Envelope.hpp"
#include "Render/Synthesizer.hpp"

using namespace SF2::Render;

@interface EnvelopeTests : XCTestCase

@end

@implementation EnvelopeTests

- (void)testGateOnOff {
    auto env = Envelope(1);
    auto gen = env.generator();
    XCTAssertEqual(0.0, gen.value());
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
    XCTAssertEqual(0.0, gen.process());
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    XCTAssertEqual(1.0, gen.process());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
}

- (void)testDelay {
    auto env = Envelope(1); // 1 sample per second to keep things easy to reason on
    env.setDelay(3);
    auto gen = env.generator();
    XCTAssertEqual(0.0, gen.value());
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
    XCTAssertEqual(0.0, gen.process());
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::delay, gen.stage());
    XCTAssertEqual(0.0, gen.process());
    XCTAssertEqual(0.0, gen.process());
    XCTAssertEqual(1.0, gen.process());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
}

- (void)testNoDelayNoAttack {
    auto env = Envelope(1);
    env.setDelay(0);
    env.setAttackRate(0.0);
    env.setHoldDuration(1.0);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::hold, gen.stage());
    XCTAssertEqual(1.0, gen.process());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
}

- (void)testAttackCurvature {
    auto epsilon = 0.001;
    auto env = Envelope(10.0);
    env.setDelay(0.0);
    env.setAttackRate(1.0, 10.0);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(0.0, gen.value());
    XCTAssertEqual(Envelope::Stage::attack, gen.stage());
    XCTAssertEqualWithAccuracy(0.104, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.207, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.310, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.411, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.512, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.611, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.709, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.807, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.904, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(1.0, gen.process(), epsilon);
}

- (void)testHold {
    auto env = Envelope(10.0);
    env.setDelay(0.0);
    env.setAttackRate(0.0, 0.0);
    env.setHoldDuration(0.30);
    env.setSustainLevel(0.75);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(1.0, gen.value());
    XCTAssertEqual(Envelope::Stage::hold, gen.stage());
    XCTAssertEqual(1.0, gen.process());
    XCTAssertEqual(1.0, gen.process());
    XCTAssertEqual(0.75, gen.process());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
}

- (void)testDecay {
    auto epsilon = 0.001;
    auto env = Envelope(10.0);
    env.setDelay(0.0);
    env.setDecayRate(1.0, 10.0);
    env.setSustainLevel(0.5);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::decay, gen.stage());
    XCTAssertEqualWithAccuracy(0.900, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.801, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.704, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.607, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.512, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.500, gen.process(), epsilon);
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
}

- (void)testDecayAborted {
    auto epsilon = 0.001;
    auto env = Envelope(10.0);
    env.setDelay(0.0);
    env.setDecayRate(1.0, 10.0);
    env.setSustainLevel(0.5);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::decay, gen.stage());
    XCTAssertEqualWithAccuracy(0.900, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.801, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.704, gen.process(), epsilon);
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
    XCTAssertEqualWithAccuracy(0.0, gen.process(), epsilon);
}

- (void)testSustain {
    auto env = Envelope(10.0);
    env.setSustainLevel(0.25);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(0.25, gen.value());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    XCTAssertEqual(0.25, gen.process());
    XCTAssertEqual(0.25, gen.process());
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
}

- (void)testRelease {
    auto epsilon = 0.001;
    auto env = Envelope(10.0);
    env.setSustainLevel(0.5);
    env.setReleaseRate(1.0, 10.0);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(0.5, gen.value());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::release, gen.stage());
    XCTAssertEqualWithAccuracy(0.400, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.302, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.204, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.107, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.011, gen.process(), epsilon);
    XCTAssertEqual(Envelope::Stage::release, gen.stage());
    XCTAssertEqualWithAccuracy(0.000, gen.process(), epsilon);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
}

@end
