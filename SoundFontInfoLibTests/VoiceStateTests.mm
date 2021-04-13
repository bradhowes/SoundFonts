// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>

#include "Entity/Generator/Index.hpp"
#include "Render/VoiceState.hpp"

using namespace SF2::Render;

@interface VoiceStateTests : XCTestCase
@end

@implementation VoiceStateTests

- (void)testInit {
    VoiceState state;
    XCTAssertEqual(0, state[SF2::Entity::Generator::Index::startAddressOffset]);
    XCTAssertEqual(0, state[SF2::Entity::Generator::Index::endAddressOffset]);
    XCTAssertEqual(13500, state[SF2::Entity::Generator::Index::initialFilterCutoff]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::delayModulatorLFO]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::delayVibratoLFO]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::attackModulatorEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::holdModulatorEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::decayModulatorEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::releaseModulatorEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::delayVolumeEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::attackVolumeEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::holdVolumeEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::decayVolumeEnvelope]);
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::releaseVolumeEnvelope]);

    XCTAssertEqual(-1, state[SF2::Entity::Generator::Index::midiKey]);
    XCTAssertEqual(-1, state[SF2::Entity::Generator::Index::midiVelocity]);
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
