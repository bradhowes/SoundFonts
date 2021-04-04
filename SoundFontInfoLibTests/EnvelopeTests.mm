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
    auto sampleRate = 1.0;
    auto config = Envelope::Config(3, 0, 0, 0, 1, 0);
    auto env = Envelope(sampleRate, config);
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
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 0, 1, 0, 1, 0);
    auto env = Envelope(sampleRate, config);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::hold, gen.stage());
    XCTAssertEqual(1.0, gen.process());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
}

- (void)testAttackCurvature {
    auto epsilon = 0.001;
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 10, 0, 0, 1, 0);
    auto env = Envelope(sampleRate, config);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(0.0, gen.value());
    XCTAssertEqual(Envelope::Stage::attack, gen.stage());
    XCTAssertEqualWithAccuracy(0.373366868371, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.60871114427, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.757055662464, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.850561637888, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.909501243789, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.946652635751, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.970070266453, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.98483109771, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.994135290015, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(1.0, gen.process(), epsilon);
}

- (void)testHold {
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 0, 3, 0, 0.75, 0);
    auto env = Envelope(sampleRate, config);
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
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 0, 0, 5, 0.5, 0);
    auto env = Envelope(sampleRate, config);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::decay, gen.stage());
    XCTAssertEqualWithAccuracy(0.692631006359, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.570508479878, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.521987282938, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.502709049671, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.500, gen.process(), epsilon);
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
}

- (void)testDecayAborted {
    auto epsilon = 0.001;
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 0, 0, 5, 0.5, 0);
    auto env = Envelope(sampleRate, config);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(Envelope::Stage::decay, gen.stage());
    XCTAssertEqualWithAccuracy(0.692631006359, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.570508479878, gen.process(), epsilon);
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
    XCTAssertEqualWithAccuracy(0.0, gen.process(), epsilon);
}

- (void)testSustain {
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 0, 0, 0, 0.25, 0);
    auto env = Envelope(sampleRate, config);
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
    auto sampleRate = 1.0;
    auto config = Envelope::Config(0, 0, 0, 0, 0.5, 5);
    auto env = Envelope(sampleRate, config);
    auto gen = env.generator();
    gen.gate(true);
    XCTAssertEqual(0.5, gen.value());
    XCTAssertEqual(Envelope::Stage::sustain, gen.stage());
    gen.gate(false);
    XCTAssertEqual(Envelope::Stage::release, gen.stage());
    XCTAssertEqualWithAccuracy(0.192631006359, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.0705084798785, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.0219872829376, gen.process(), epsilon);
    XCTAssertEqualWithAccuracy(0.00270904967126, gen.process(), epsilon);
    XCTAssertEqual(Envelope::Stage::release, gen.stage());
    XCTAssertEqualWithAccuracy(0.000, gen.process(), epsilon);
    XCTAssertEqual(Envelope::Stage::idle, gen.stage());
}

@end
