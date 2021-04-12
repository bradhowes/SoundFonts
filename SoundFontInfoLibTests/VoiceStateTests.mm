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
    XCTAssertEqual(0, state[SF2::Entity::Generator::Index::startAddressOffset].index());
    XCTAssertEqual(0, state[SF2::Entity::Generator::Index::endAddressOffset].index());
    XCTAssertEqual(13500, state[SF2::Entity::Generator::Index::initialFilterCutoff].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::delayModulatorLFO].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::delayVibratoLFO].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::attackModulatorEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::holdModulatorEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::decayModulatorEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::releaseModulatorEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::delayVolumeEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::attackVolumeEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::holdVolumeEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::decayVolumeEnvelope].amount());
    XCTAssertEqual(-12000, state[SF2::Entity::Generator::Index::releaseVolumeEnvelope].amount());

    XCTAssertEqual(-1, state[SF2::Entity::Generator::Index::midiKey].amount());
    XCTAssertEqual(-1, state[SF2::Entity::Generator::Index::midiVelocity].amount());
    XCTAssertEqual(100, state[SF2::Entity::Generator::Index::scaleTuning].amount());
    XCTAssertEqual(-1, state[SF2::Entity::Generator::Index::overridingRootKey].amount());

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
