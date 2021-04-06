// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "DSP.hpp"

@interface DSPTests : XCTestCase

@end

@implementation DSPTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUnipolarModulation {
    XCTAssertEqual(SF2::DSP::unipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(0.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(0.5, 10.0, 20.0), 15.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(1.0, 10.0, 20.0), 20.0);
    XCTAssertEqual(SF2::DSP::unipolarModulation(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
    XCTAssertEqual(SF2::DSP::bipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(-1.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(0.0, 10.0, 20.0), 15.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(1.0, 10.0, 20.0), 20.0);

    XCTAssertEqual(SF2::DSP::bipolarModulation(-1.0, -20.0, 13.0), -20.0);
    XCTAssertEqual(SF2::DSP::bipolarModulation(0.0,  -20.0, 13.0), -3.5);
    XCTAssertEqual(SF2::DSP::bipolarModulation(1.0,  -20.0, 13.0), 13.0);
}

- (void)testUnipolarToBipolar {
    XCTAssertEqual(SF2::DSP::unipolarToBipolar(0.0), -1.0);
    XCTAssertEqual(SF2::DSP::unipolarToBipolar(0.5), 0.0);
    XCTAssertEqual(SF2::DSP::unipolarToBipolar(1.0), 1.0);
}

- (void)testBipolarToUnipolar {
    XCTAssertEqual(SF2::DSP::bipolarToUnipolar(-1.0), 0.0);
    XCTAssertEqual(SF2::DSP::bipolarToUnipolar(0.0), 0.5);
    XCTAssertEqual(SF2::DSP::bipolarToUnipolar(1.0), 1.0);
}

- (void)testParabolicSineAccuracy {
    for (int index = 0; index < 360.0; ++index) {
        auto theta = 2.0 * M_PI * index / 360.0 - M_PI;
        auto real = std::sin(theta);
        XCTAssertEqualWithAccuracy(SF2::DSP::parabolicSine(theta), real, 0.0011);
    }
}

- (void)testZZZ {
    for (float modulator = -1.0; modulator <= 1.0; modulator += 0.1) {
        auto a = SF2::DSP::unipolarModulation<float>(SF2::DSP::bipolarToUnipolar<float>(modulator), 0.0, 10.0);
        auto b = SF2::DSP::bipolarModulation<float>(modulator, 0.0, 10.0);
        NSLog(@"%f %f", a, b);
    }
}

@end
