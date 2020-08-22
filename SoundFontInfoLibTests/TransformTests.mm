//
//  EnvelopeTests.m
//  SoundFontInfoLibTests
//
//  Created by Brad Howes on 8/19/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "Transform.hpp"

using namespace SF2;

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
    auto xfm = Transform(Transform::Kind::linear, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.503937, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(127), self.epsilon);
}

- (void)testBipolarLinear {
    auto xfm = Transform(Transform::Kind::linear, Transform::Direction::ascending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(-1.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.007874, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(127), self.epsilon);
}

- (void)testDescendingBipolarLinear {
    auto xfm = Transform(Transform::Kind::linear, Transform::Direction::descending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.007874, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(-1.0, xfm.value(127), self.epsilon);
}

- (void)testAscendingConcave {
    auto xfm = Transform(Transform::Kind::concave, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.126859654793, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(127), self.epsilon);
}

- (void)testDescendingConcave {
    auto xfm = Transform(Transform::Kind::concave, Transform::Direction::descending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.124009894572, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(127), self.epsilon);
}

- (void)testBipolarAscendingConcave {
    auto xfm = Transform(Transform::Kind::concave, Transform::Direction::ascending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(-1.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(-0.746280690415, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(127), self.epsilon);
}

- (void)testAscendingConvex {
    auto xfm = Transform(Transform::Kind::convex, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.875990105428, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(127), self.epsilon);
}

- (void)testDescendingConvex {
    auto xfm = Transform(Transform::Kind::convex, Transform::Direction::descending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.873140345207, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(127), self.epsilon);
}

- (void)testUnipolarSwitched {
    auto xfm = Transform(Transform::Kind::switched, Transform::Direction::ascending, Transform::Polarity::unipolar);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.0, xfm.value(63), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy(1.0, xfm.value(127), self.epsilon);
}

- (void)testBipolarSwitched {
    auto xfm = Transform(Transform::Kind::switched, Transform::Direction::ascending, Transform::Polarity::bipolar);
    XCTAssertEqualWithAccuracy(-1.0, xfm.value(0), self.epsilon);
    XCTAssertEqualWithAccuracy(-1.0, xfm.value(63), self.epsilon);
    XCTAssertEqualWithAccuracy( 1.0, xfm.value(64), self.epsilon);
    XCTAssertEqualWithAccuracy( 1.0, xfm.value(127), self.epsilon);
}


@end
