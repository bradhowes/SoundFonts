// Copyright © 2020 Brad Howes. All rights reserved.


#import <XCTest/XCTest.h>

#include "Render/Utils.hpp"

@interface RenderUtilsTests : XCTestCase
@end

@implementation RenderUtilsTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testCentsToDurationDelay {
    XCTAssertEqual(0.0, SF2::Render::Utils::centsToDurationDelay(-32768));
    XCTAssertEqualWithAccuracy(0.000173, SF2::Render::Utils::centsToDurationDelay(-20000), 0.000001);
    XCTAssertEqualWithAccuracy(0.009998, SF2::Render::Utils::centsToDurationDelay(-7973), 0.000001);
    XCTAssertEqualWithAccuracy(1.0, SF2::Render::Utils::centsToDurationDelay(0), 0.000001);
    XCTAssertEqualWithAccuracy(10.0, SF2::Render::Utils::centsToDurationDelay(3986), 0.005);
    XCTAssertEqualWithAccuracy(20.0, SF2::Render::Utils::centsToDurationDelay(5186), 0.005);
    XCTAssertEqualWithAccuracy(20.0, SF2::Render::Utils::centsToDurationDelay(9000), 0.005);
}

- (void)testCentsToDurationAttack {
    XCTAssertEqual(0.0, SF2::Render::Utils::centsToDurationAttack(-32768));
    XCTAssertEqualWithAccuracy(0.000173, SF2::Render::Utils::centsToDurationAttack(-20000), 0.000001);
    XCTAssertEqualWithAccuracy(0.009998, SF2::Render::Utils::centsToDurationAttack(-7973), 0.000001);
    XCTAssertEqualWithAccuracy(1.0, SF2::Render::Utils::centsToDurationAttack(0), 0.000001);
    XCTAssertEqualWithAccuracy(10.0, SF2::Render::Utils::centsToDurationAttack(3986), 0.005);
    XCTAssertEqualWithAccuracy(20.0, SF2::Render::Utils::centsToDurationAttack(5186), 0.005);
    XCTAssertEqualWithAccuracy(101.593658, SF2::Render::Utils::centsToDurationAttack(8000), 0.005);
    XCTAssertEqualWithAccuracy(101.593658, SF2::Render::Utils::centsToDurationAttack(9000), 0.005);
}

- (void)testCentsToFrequency {
    XCTAssertEqualWithAccuracy(0.000792, SF2::Render::Utils::absoluteCentsToFrequency(-32768), 0.000001);
    XCTAssertEqualWithAccuracy(0.000792, SF2::Render::Utils::absoluteCentsToFrequency(-20000), 0.000001);
    XCTAssertEqualWithAccuracy(8.175799, SF2::Render::Utils::absoluteCentsToFrequency(0), 0.00001);
    XCTAssertEqualWithAccuracy(110.0, SF2::Render::Utils::absoluteCentsToFrequency(4500), 0.00001);
    XCTAssertEqualWithAccuracy(110.0, SF2::Render::Utils::absoluteCentsToFrequency(9000), 0.00001);
}

- (void)testCentiBelToAttenuation {
    XCTAssertEqual(1.0, SF2::Render::Utils::centiBelToAttenuation(0));
    XCTAssertEqual(1.0, SF2::Render::Utils::centiBelToAttenuation(-100));
    XCTAssertEqualWithAccuracy(0.794328, SF2::Render::Utils::centiBelToAttenuation(20), 0.00001);
    XCTAssertEqualWithAccuracy(0.630957, SF2::Render::Utils::centiBelToAttenuation(40), 0.00001);
    XCTAssertEqualWithAccuracy(0.190546, SF2::Render::Utils::centiBelToAttenuation(144), 0.00001);
    XCTAssertEqualWithAccuracy(0.0, SF2::Render::Utils::centiBelToAttenuation(1440), 0.00001);
    XCTAssertEqualWithAccuracy(0.0, SF2::Render::Utils::centiBelToAttenuation(4400), 0.00001);
}

- (void)testPanAttenuation {
    auto pair = SF2::Render::Utils::panAttenuation(-500);
    XCTAssertEqualWithAccuracy(1.0, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(0.0, pair.second, 0.00001);

    pair = SF2::Render::Utils::panAttenuation(-1000);
    XCTAssertEqualWithAccuracy(1.0, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(0.0, pair.second, 0.00001);

    pair = SF2::Render::Utils::panAttenuation(500);
    XCTAssertEqualWithAccuracy(0.0, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(1.0, pair.second, 0.00001);

    pair = SF2::Render::Utils::panAttenuation(1000);
    XCTAssertEqualWithAccuracy(0.0, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(1.0, pair.second, 0.00001);

    pair = SF2::Render::Utils::panAttenuation(0.0);
    XCTAssertEqualWithAccuracy(0.7071067811865476, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(0.7071067811865476, pair.second, 0.00001);

    pair = SF2::Render::Utils::panAttenuation(-250.0);
    XCTAssertEqualWithAccuracy(0.9238795325112867, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(0.38268343236508984, pair.second, 0.00001);

    pair = SF2::Render::Utils::panAttenuation(250.0);
    XCTAssertEqualWithAccuracy(0.38268343236508984, pair.first, 0.00001);
    XCTAssertEqualWithAccuracy(0.9238795325112867, pair.second, 0.00001);
}

@end
