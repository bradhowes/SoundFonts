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
    XCTAssertEqual(DSP::unipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::unipolarModulation(0.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::unipolarModulation(0.5, 10.0, 20.0), 15.0);
    XCTAssertEqual(DSP::unipolarModulation(1.0, 10.0, 20.0), 20.0);
    XCTAssertEqual(DSP::unipolarModulation(11.0, 10.0, 20.0), 20.0);
}

- (void)testBipolarModulation {
    XCTAssertEqual(DSP::bipolarModulation(-3.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::bipolarModulation(-1.0, 10.0, 20.0), 10.0);
    XCTAssertEqual(DSP::bipolarModulation(0.0, 10.0, 20.0), 15.0);
    XCTAssertEqual(DSP::bipolarModulation(1.0, 10.0, 20.0), 20.0);

    XCTAssertEqual(DSP::bipolarModulation(-1.0, -20.0, 13.0), -20.0);
    XCTAssertEqual(DSP::bipolarModulation(0.0,  -20.0, 13.0), -3.5);
    XCTAssertEqual(DSP::bipolarModulation(1.0,  -20.0, 13.0), 13.0);
}

- (void)testUnipolarToBipolar {
    XCTAssertEqual(DSP::unipolarToBipolar(0.0), -1.0);
    XCTAssertEqual(DSP::unipolarToBipolar(0.5), 0.0);
    XCTAssertEqual(DSP::unipolarToBipolar(1.0), 1.0);
}

- (void)testBipolarToUnipolar {
    XCTAssertEqual(DSP::bipolarToUnipolar(-1.0), 0.0);
    XCTAssertEqual(DSP::bipolarToUnipolar(0.0), 0.5);
    XCTAssertEqual(DSP::bipolarToUnipolar(1.0), 1.0);
}

- (void)testParabolicSineAccuracy {
    for (int index = 0; index < 360.0; ++index) {
        auto theta = 2.0 * M_PI * index / 360.0 - M_PI;
        auto real = std::sin(theta);
        XCTAssertEqualWithAccuracy(DSP::parabolicSine(theta), real, 0.0011);
    }
}

- (void)testZZZ {
    for (float modulator = -1.0; modulator <= 1.0; modulator += 0.1) {
        auto a = DSP::unipolarModulation<float>(DSP::bipolarToUnipolar<float>(modulator), 0.0, 10.0);
        auto b = DSP::bipolarModulation<float>(modulator, 0.0, 10.0);
        NSLog(@"%f %f", a, b);
    }
}

@end
