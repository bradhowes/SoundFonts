// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Render/MIDI.hpp"

using namespace SF2::Render;

@interface MIDITests : XCTestCase
@property (nonatomic, assign) double epsilon;
@end

@implementation MIDITests

- (void)setUp {
    self.epsilon = 0.0000001;
}

- (void)testKeyToFrequency {
    XCTAssertEqualWithAccuracy(8.1757989156, MIDI::keyToFrequency<double>(12 * 0), self.epsilon);  // C-1
    XCTAssertEqualWithAccuracy(16.3515978313, MIDI::keyToFrequency<double>(12 * 1), self.epsilon); // C0
    XCTAssertEqualWithAccuracy(32.7031956624, MIDI::keyToFrequency<double>(12 * 2), self.epsilon); // C1
    XCTAssertEqualWithAccuracy(65.4063913248, MIDI::keyToFrequency<double>(12 * 3), self.epsilon); // C2
    XCTAssertEqualWithAccuracy(130.81278265, MIDI::keyToFrequency<double>(12 * 4), self.epsilon);  // C3
    XCTAssertEqualWithAccuracy(261.625565299, MIDI::keyToFrequency<double>(12 * 5), self.epsilon); // C4
    XCTAssertEqualWithAccuracy(440.0, MIDI::keyToFrequency<double>(12 * 5 + 9), self.epsilon);     // A4
    XCTAssertEqualWithAccuracy(11839.8215268, MIDI::keyToFrequency<double>(126), self.epsilon);    // F#9
    XCTAssertEqualWithAccuracy(12543.8539514, MIDI::keyToFrequency<double>(127), self.epsilon);    // G9
}

@end
