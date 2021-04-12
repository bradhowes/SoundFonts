// Copyright © 2020 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>

#include "Render/Transform.hpp"

using namespace SF2::Render;

@interface TransformTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation TransformTests

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)tearDown {
}

- (void)testUnipolarLinear {
    auto z = Transform(Transform::Kind::linear, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.251968503937, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(0.503937, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.755905511811, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testBipolarLinear {
    auto z = Transform(Transform::Kind::linear, Transform::Direction::ascending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.496062992126, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(0.007874, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.511811023622, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testDescendingBipolarLinear {
    auto z = Transform(Transform::Kind::linear, Transform::Direction::descending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.496062992126, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.007874, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.511811023622, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(-1.0, z.value(127), self.epsilon);
}

- (void)testAscendingConcave {
    auto z = Transform(Transform::Kind::concave, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.052533381528, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(0.126859654793, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.255184177967, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testDescendingConcave {
    auto z = Transform(Transform::Kind::concave, Transform::Direction::descending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.249439059432, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(0.124009894572, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0506385366318, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, z.value(127), self.epsilon);
}

- (void)testBipolarAscendingConcave {
    auto z = Transform(Transform::Kind::concave, Transform::Direction::ascending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.894933236944, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.746280690415, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.489631644065, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testAscendingConvex {
    auto z = Transform(Transform::Kind::convex, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.750560940568, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(0.875990105428, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.949361463368, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testDescendingConvex {
    auto z = Transform(Transform::Kind::convex, Transform::Direction::descending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(1.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.947466618472, z.value(32), self.epsilon);
    XCTAssertEqualWithAccuracy(0.873140345207, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.744815822033, z.value(96), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, z.value(127), self.epsilon);
}

- (void)testUnipolarSwitched {
    auto z = Transform(Transform::Kind::switched, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, z.value(63), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, z.value(127), self.epsilon);
}

- (void)testBipolarSwitched {
    auto z = Transform(Transform::Kind::switched, Transform::Direction::ascending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(-1.0, z.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(-1.0, z.value(63), self.epsilon);
    XCTAssertEqualWithAccuracy( 1.0, z.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy( 1.0, z.value(127), self.epsilon);
}


@end
