//
//  EnvelopeTests.m
//  SoundFontInfoLibTests
//
//  Created by Brad Howes on 8/19/20.
//  Copyright © 2020 Brad Howes. All rights reserved.
//

#import <iostream>

#import <XCTest/XCTest.h>

#include "Synthesizer.hpp"

using namespace SF2;

@interface SynthesizerTests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation SynthesizerTests

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)tearDown {
}

- (void)testMidiKeyToFrequency {
    XCTAssertEqualWithAccuracy(8.1757989156, Synthesizer::midiKeyToFrequency(12 * 0), self.epsilon);  // C-1
    XCTAssertEqualWithAccuracy(16.3515978313, Synthesizer::midiKeyToFrequency(12 * 1), self.epsilon); // C0
    XCTAssertEqualWithAccuracy(32.7031956624, Synthesizer::midiKeyToFrequency(12 * 2), self.epsilon); // C1
    XCTAssertEqualWithAccuracy(65.4063913248, Synthesizer::midiKeyToFrequency(12 * 3), self.epsilon); // C2
    XCTAssertEqualWithAccuracy(130.81278265, Synthesizer::midiKeyToFrequency(12 * 4), self.epsilon);  // C3
    XCTAssertEqualWithAccuracy(261.625565299, Synthesizer::midiKeyToFrequency(12 * 5), self.epsilon); // C4
    XCTAssertEqualWithAccuracy(440.0, Synthesizer::midiKeyToFrequency(12 * 5 + 9), self.epsilon);     // A4
    XCTAssertEqualWithAccuracy(11839.8215268, Synthesizer::midiKeyToFrequency(126), self.epsilon);    // F#9
    XCTAssertEqualWithAccuracy(12543.8539514, Synthesizer::midiKeyToFrequency(127), self.epsilon);    // G9
}

- (void)testCentFrequencyMultiplier {
    XCTAssertEqualWithAccuracy(0.5, Synthesizer::centToFrequencyMultiplier(-1200), self.epsilon); // -1200 = 1/2x
    XCTAssertEqualWithAccuracy(1.0, Synthesizer::centToFrequencyMultiplier(0), self.epsilon); // 0 = 1x
    XCTAssertEqualWithAccuracy(2.0, Synthesizer::centToFrequencyMultiplier(1200), self.epsilon); // +1200 = 2x
}

- (void)testSinLookup {
    XCTAssertEqualWithAccuracy(0.0, Synthesizer::sineLookup(0.0), self.epsilon);
    XCTAssertEqualWithAccuracy(0.707106768181, Synthesizer::sineLookup(Synthesizer::QuarterPI), self.epsilon); // 45°
    XCTAssertEqualWithAccuracy(1.0, Synthesizer::sineLookup(Synthesizer::HalfPI - 0.0000001), self.epsilon); // 90°
}

- (void)testSin {
    // self.epsilon = 0.001;
    for (int degrees = -720; degrees <= 720; degrees += 10) {
        double radians = degrees * Synthesizer::PI / 180.0;
        double value = Synthesizer::sin(radians);
        std::cout << degrees << " " << value << std::endl;
        XCTAssertEqualWithAccuracy(::std::sin(radians), Synthesizer::sin(radians), self.epsilon);
    }
}

@end
