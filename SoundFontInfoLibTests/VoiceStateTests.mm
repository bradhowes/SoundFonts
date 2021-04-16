// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Index.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2::Render::Voice;
using namespace SF2::Entity::Generator;

@interface VoiceStateTests : XCTestCase
@end

@implementation VoiceStateTests

- (void)testInit {
    double epsilon = 0.000001;
    State state;
    XCTAssertEqual(0, state[Index::startAddressOffset]);
    XCTAssertEqual(0, state[Index::endAddressOffset]);
    XCTAssertEqualWithAccuracy(19912.1269582, state[Index::initialFilterCutoff], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::delayModulatorLFO], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::delayVibratoLFO], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::attackModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::holdModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::decayModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::releaseModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::delayVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::attackVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::holdVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::decayVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[Index::releaseVolumeEnvelope], epsilon);

    XCTAssertEqual(-1, state[Index::forcedMIDIKey]);
    XCTAssertEqual(-1, state[Index::forcedMIDIVelocity]);
    XCTAssertEqual(100, state[Index::scaleTuning]);
    XCTAssertEqual(-1, state[Index::overridingRootKey]);

//    setAmount(Index::delayVibratoLFO, -12000);
//    setAmount(Index::delayModulatorEnvelope, -12000);
//    setAmount(Index::attackModulatorEnvelope, -12000);
//    setAmount(Index::holdModulatorEnvelope, -12000);
//    setAmount(Index::decayModulatorEnvelope, -12000);
//    setAmount(Index::releaseModulatorEnvelope, -12000);
//    setAmount(Index::delayVolumeEnvelope, -12000);
//    setAmount(Index::attackVolumeEnvelope, -12000);
//    setAmount(Index::holdVolumeEnvelope, -12000);
//    setAmount(Index::decayVolumeEnvelope, -12000);
//    setAmount(Index::sustainVolumeEnvelope, -12000);
//    setAmount(Index::releaseVolumeEnvelope, -12000);
//    setAmount(Index::midiKey, -1);
//    setAmount(Index::midiVelocity, -1);
//    setAmount(Index::scaleTuning, 100);
//    setAmount(Index::overridingRootKey, -1);
}

@end
