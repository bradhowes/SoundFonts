// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Modulator/Source.hpp"

using namespace SF2::Entity::Modulator;

@interface ModulatorSourceTests : XCTestCase
@end

@implementation ModulatorSourceTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testValidity {
    Source s(0);
    XCTAssertTrue(s.isValid());
    XCTAssertTrue(s.isUnipolar());
    XCTAssertTrue(s.isMinToMax());
    XCTAssertEqual(Source::ContinuityType::linear, s.type());
    XCTAssertEqual("linear", s.typeName());

    XCTAssertFalse(s.isContinuousController());
    XCTAssertFalse(s.isBipolar());
    XCTAssertFalse(s.isMaxToMin());
}

- (void)testLinear {
    Source s(0 << 10);
    XCTAssertTrue(s.isValid());
    XCTAssertTrue(s.isUnipolar());
    XCTAssertTrue(s.isMinToMax());
    XCTAssertEqual(Source::ContinuityType::linear, s.type());
    XCTAssertEqual("linear", s.typeName());
}

- (void)testConcave {
    Source s(1 << 10);
    XCTAssertTrue(s.isValid());
    XCTAssertTrue(s.isUnipolar());
    XCTAssertTrue(s.isMinToMax());
    XCTAssertEqual(Source::ContinuityType::concave, s.type());
    XCTAssertEqual("concave", s.typeName());
}

- (void)testConvex {
    Source s(2 << 10);
    XCTAssertTrue(s.isValid());
    XCTAssertTrue(s.isUnipolar());
    XCTAssertTrue(s.isMinToMax());
    XCTAssertEqual(Source::ContinuityType::convex, s.type());
    XCTAssertEqual("convex", s.typeName());
}

- (void)testSwitched {
    Source s(3 << 10);
    XCTAssertTrue(s.isValid());
    XCTAssertTrue(s.isUnipolar());
    XCTAssertTrue(s.isMinToMax());
    XCTAssertEqual(Source::ContinuityType::switched, s.type());
    XCTAssertEqual("switched", s.typeName());
}

- (void)testGeneralIndices {
    for (auto bits : {0, 2, 3, 10, 13, 14, 16, 127}) {
        Source s(bits);
        XCTAssertTrue(s.isValid());
        XCTAssertFalse(s.isContinuousController());
        XCTAssertEqual(Source::GeneralIndex(bits), s.generalIndex());
    }

    for (auto bits : {1, 4, 5, 11, 126}) {
        Source s(bits);
        XCTAssertFalse(s.isValid());
        XCTAssertFalse(s.isContinuousController());
    }
}

- (void)testContinuousIndices {
    for (auto bits : {1, 2, 3, 4, 31, 64, 97, 119}) {
        Source s(bits | (1 << 7));
        XCTAssertTrue(s.isValid());
        XCTAssertTrue(s.isContinuousController());
        XCTAssertEqual(bits, s.continuousIndex());
    }

    for (auto bits : {0, 6, 32, 63, 98, 101, 120, 127}) {
        Source s(bits | (1 << 7));
        XCTAssertFalse(s.isValid());
        XCTAssertTrue(s.isContinuousController());
    }
}

- (void)testDirection {
    Source s(0);
    XCTAssertTrue(s.isMinToMax());
    XCTAssertFalse(s.isMaxToMin());
    s = Source(1 << 8);
    XCTAssertFalse(s.isMinToMax());
    XCTAssertTrue(s.isMaxToMin());
}


- (void)testPolarity {
    Source s(0);
    XCTAssertTrue(s.isUnipolar());
    XCTAssertFalse(s.isBipolar());
    s = Source(1 << 9);
    XCTAssertFalse(s.isUnipolar());
    XCTAssertTrue(s.isBipolar());
}

@end
