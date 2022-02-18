// Copyright © 2020 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#include "Entity/Modulator/Source.hpp"
#include "MIDI/ValueTransformer.hpp"

using namespace SF2::MIDI;
using VT = SF2::MIDI::ValueTransformer;
using ES = SF2::Entity::Modulator::Source;

@interface ValueTransformerTests : XCTestCase
@property (nonatomic, assign) SF2::Float epsilon;
@end

@implementation ValueTransformerTests

- (void)setUp {
  self.epsilon = 0.0000001;
}

- (void)tearDown {
}

static VT makeVT(VT::Kind kind, VT::Polarity polarity, VT::Direction direction) {
  return VT(ES((static_cast<int>(kind) << 10) +
               (static_cast<int>(polarity) << 9) +
               (static_cast<int>(direction) << 8)));
}

- (void)testLinearAscendingUnipolar {
  auto z = makeVT(VT::Kind::linear, VT::Polarity::unipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.25, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.5, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.75, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(127.0 / 128.0, z.value(127), self.epsilon);
}

- (void)testLinearDescendingUnipolar {
  auto z = makeVT(VT::Kind::linear, VT::Polarity::unipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.75, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.5, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.25, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0 - 127.0 / 128.0, z.value(127), self.epsilon);
}

- (void)testLinearAscendingBipolar {
  auto z = makeVT(VT::Kind::linear, VT::Polarity::bipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.5, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.5, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(127.0 / 128.0 * 2.0 - 1.0, z.value(127), self.epsilon);
}

- (void)testLinearDescendingBipolar {
  auto z = makeVT(VT::Kind::linear, VT::Polarity::bipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.5, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.0, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.5, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy((1.0 - 127.0 / 128.0) * 2 - 1.0, z.value(127), self.epsilon);
}

- (void)testConcaveAscendingUnipolar {
  auto z = makeVT(VT::Kind::concave, VT::Polarity::unipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.052533381528, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.126859654793, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.255184177967, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(0.876584883732, z.value(126), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testConcaveDescendingUnipolar {
  auto z = makeVT(VT::Kind::concave, VT::Polarity::unipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.249439059432, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.124009894572, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0506385366318, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, z.value(127), self.epsilon);
}

- (void)testConcaveAscendingBipolar {
  auto z = makeVT(VT::Kind::concave, VT::Polarity::bipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.894933236944, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.746280690415, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.489631644065, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testConcaveDescendingBipolar {
  auto z = makeVT(VT::Kind::concave, VT::Polarity::bipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.501121881137, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.751980210857, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(-0.898722926736, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(-1.0, z.value(127), self.epsilon);
}

- (void)testConvexAscendingUnipolar {
  auto z = makeVT(VT::Kind::convex, VT::Polarity::unipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.750560940568, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.875990105428, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.949361463368, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testConvexDescendingUnipolar {
  auto z = makeVT(VT::Kind::convex, VT::Polarity::unipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.947466618472, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.873140345207, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.744815822033, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, z.value(127), self.epsilon);
}

- (void)testConvexAscendingBipolar {
  auto z = makeVT(VT::Kind::convex, VT::Polarity::bipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.501121881137, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.751980210857, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.898722926736, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testConvexDescendingBipolar {
  auto z = makeVT(VT::Kind::convex, VT::Polarity::bipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.894933236944, z.value(32), self.epsilon);
  XCTAssertEqualWithAccuracy(0.746280690415, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.489631644065, z.value(96), self.epsilon);
  XCTAssertEqualWithAccuracy(-1.0, z.value(127), self.epsilon);
}

- (void)testSwitchedAscendingUnipolar {
  auto z = makeVT(VT::Kind::switched, VT::Polarity::unipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, z.value(63), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testSwitchedDescendingUnipolar {
  auto z = makeVT(VT::Kind::switched, VT::Polarity::unipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(63), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(0.0, z.value(127), self.epsilon);
}

- (void)testSwitchedAscendingBipolar {
  auto z = makeVT(VT::Kind::switched, VT::Polarity::bipolar, VT::Direction::ascending);
  XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(-1.0, z.value(63), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testSwitchedDescendingBipolar {
  auto z = makeVT(VT::Kind::switched, VT::Polarity::bipolar, VT::Direction::descending);
  XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
  XCTAssertEqualWithAccuracy(1.0, z.value(63), self.epsilon);
  XCTAssertEqualWithAccuracy(-1.0, z.value(64), self.epsilon);
  XCTAssertEqualWithAccuracy(-1.0, z.value(127), self.epsilon);
}


@end
