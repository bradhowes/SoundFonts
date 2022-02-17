//// Copyright © 2020 Brad Howes. All rights reserved.
//
//#import <XCTest/XCTest.h>
//
//#include "DSP/DSP.hpp"
//#include "Render/Envelope/Generator.hpp"
//#include "Render/Envelope/Stage.hpp"
//#include "Render/Voice/State.hpp"
//
//using namespace SF2::Render::Envelope;
//
//@interface EnvelopeTests : XCTestCase
//State state;
//@end
//
//@implementation EnvelopeTests
//
//
//- (void)setUp {
//
//}
//- (void)testGateOnOff {
//  auto gen = Generator(1);
//  XCTAssertEqual(0.0, gen.value());
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//  XCTAssertEqual(0.0, gen.process());
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//  XCTAssertTrue(!gen.isGated());
//  gen.gate(true);
//  XCTAssertTrue(gen.isGated());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//  XCTAssertEqual(1.0, gen.process());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//  XCTAssertTrue(gen.isGated());
//  gen.gate(false);
//  XCTAssertTrue(!gen.isGated());
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//}
//
//- (void)testDelay {
//  auto gen = Generator(1.0, 3, 0, 0, 0, 1, 0);
//  XCTAssertEqual(0.0, gen.value());
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//  XCTAssertEqual(0.0, gen.process());
//  gen.gate(true);
//  XCTAssertEqual(StageIndex::delay, gen.stage());
//  XCTAssertEqual(0.0, gen.process());
//  XCTAssertEqual(0.0, gen.process());
//  XCTAssertEqual(1.0, gen.process());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//}
//
//- (void)testNoDelayNoAttack {
//  auto gen = Generator(1.0, 0, 0, 1, 0, 1, 0);
//  gen.gate(true);
//  XCTAssertEqual(StageIndex::hold, gen.stage());
//  XCTAssertEqual(1.0, gen.process());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//}
//
//- (void)testAttackCurvature {
//  auto epsilon = 0.001;
//  auto gen = Generator(1.0, 0, 10, 0, 0, 1, 0);
//  gen.gate(true);
//  XCTAssertEqual(0.0, gen.value());
//  XCTAssertEqual(StageIndex::attack, gen.stage());
//  XCTAssertEqualWithAccuracy(0.373366868371, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.60871114427, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.757055662464, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.850561637888, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.909501243789, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.946652635751, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.970070266453, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.98483109771, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.994135290015, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(1.0, gen.process(), epsilon);
//}
//
//- (void)testHold {
//  auto gen = Generator(1.0, 0, 0, 3, 0, 0.75, 0);
//  gen.gate(true);
//  XCTAssertEqual(1.0, gen.value());
//  XCTAssertEqual(StageIndex::hold, gen.stage());
//  XCTAssertEqual(1.0, gen.process());
//  XCTAssertEqual(1.0, gen.process());
//  XCTAssertEqual(0.75, gen.process());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//}
//
//- (void)testDecay {
//  auto epsilon = 0.001;
//  auto gen = Generator(1.0, 0, 0, 0, 5, 0.5, 0);
//  gen.gate(true);
//  XCTAssertEqual(StageIndex::decay, gen.stage());
//  XCTAssertEqualWithAccuracy(0.692631006359, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.570508479878, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.521987282938, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.502709049671, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.500, gen.process(), epsilon);
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//  gen.gate(false);
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//}
//
//- (void)testDecayAborted {
//  auto epsilon = 0.001;
//  auto gen = Generator(1.0, 0, 0, 0, 5, 0.5, 0);
//  gen.gate(true);
//  XCTAssertEqual(StageIndex::decay, gen.stage());
//  XCTAssertEqualWithAccuracy(0.692631006359, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.570508479878, gen.process(), epsilon);
//  gen.gate(false);
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//  XCTAssertEqualWithAccuracy(0.0, gen.process(), epsilon);
//}
//
//- (void)testSustain {
//  auto gen = Generator(1.0, 0, 0, 0, 0, 0.25, 0);
//  gen.gate(true);
//  XCTAssertEqual(0.25, gen.value());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//  XCTAssertEqual(0.25, gen.process());
//  XCTAssertEqual(0.25, gen.process());
//  gen.gate(false);
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//}
//
//- (void)testRelease {
//  auto epsilon = 0.001;
//  auto gen = Generator(1.0, 0, 0, 0, 0, 0.5, 5);
//  gen.gate(true);
//  XCTAssertEqual(0.5, gen.value());
//  XCTAssertEqual(StageIndex::sustain, gen.stage());
//  gen.gate(false);
//  XCTAssertEqual(StageIndex::release, gen.stage());
//  XCTAssertEqualWithAccuracy(0.192631006359, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.0705084798785, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.0219872829376, gen.process(), epsilon);
//  XCTAssertEqualWithAccuracy(0.00270904967126, gen.process(), epsilon);
//  XCTAssertEqual(StageIndex::release, gen.stage());
//  XCTAssertEqualWithAccuracy(0.000, gen.process(), epsilon);
//  XCTAssertEqual(StageIndex::idle, gen.stage());
//}
//
//@end
