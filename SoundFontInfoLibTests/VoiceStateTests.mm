// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Index.hpp"
#include "Render/Voice/VoiceState.hpp"

using namespace SF2::Render;

@interface VoiceStateTests : XCTestCase
@end

@implementation VoiceStateTests

- (void)testInit {
    double epsilon = 0.000001;
    VoiceState state;
    XCTAssertEqual(0, state[SF2::Entity::Generator::Index::startAddressOffset]);
    XCTAssertEqual(0, state[SF2::Entity::Generator::Index::endAddressOffset]);
    XCTAssertEqualWithAccuracy(19912.1269582, state[SF2::Entity::Generator::Index::initialFilterCutoff], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::delayModulatorLFO], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::delayVibratoLFO], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::attackModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::holdModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::decayModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::releaseModulatorEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::delayVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::attackVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::holdVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::decayVolumeEnvelope], epsilon);
    XCTAssertEqualWithAccuracy(0.0009765625, state[SF2::Entity::Generator::Index::releaseVolumeEnvelope], epsilon);

    XCTAssertEqual(65535, state[SF2::Entity::Generator::Index::midiKey]);
    XCTAssertEqual(65535, state[SF2::Entity::Generator::Index::midiVelocity]);
    XCTAssertEqual(100, state[SF2::Entity::Generator::Index::scaleTuning]);
    XCTAssertEqual(-1, state[SF2::Entity::Generator::Index::overridingRootKey]);

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
