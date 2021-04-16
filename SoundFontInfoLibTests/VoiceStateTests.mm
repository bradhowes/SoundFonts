// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "Entity/Generator/Index.hpp"
#include "Render/Preset.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Entity::Generator;

static NSArray<NSURL*>* urls = SF2Files.allResources;

@interface VoiceStateTests : XCTestCase
@end

@implementation VoiceStateTests

- (void)testInit {
    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);
    auto found = preset.find(69, 64);

    double epsilon = 0.000001;
    Voice::State state{44100, found[0]};

    XCTAssertEqual(0, state[Index::startAddressOffset]);
    XCTAssertEqual(0, state[Index::endAddressOffset]);
    XCTAssertEqualWithAccuracy(1499.77085765, state[Index::initialFilterCutoff], epsilon);
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
    XCTAssertEqualWithAccuracy(3.25088682907, state[Index::releaseVolumeEnvelope], epsilon);

    XCTAssertEqual(-1, state[Index::forcedMIDIKey]);
    XCTAssertEqual(-1, state[Index::forcedMIDIVelocity]);
    XCTAssertEqual(100, state[Index::scaleTuning]);
    XCTAssertEqual(-1, state[Index::overridingRootKey]);
}

@end
