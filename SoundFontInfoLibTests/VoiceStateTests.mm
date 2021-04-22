// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "Entity/Generator/Index.hpp"
#import "Render/MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "Render/Voice/State.hpp"

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

    MIDI::Channel channel;
    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);
    auto found = preset.find(69, 64);

    Voice::State state{44100, channel, found[0]};

    XCTAssertEqual(0, state.unmodulated(Index::startAddressOffset));
    XCTAssertEqual(0, state.unmodulated(Index::endAddressOffset));
    XCTAssertEqual(9023, state.unmodulated(Index::initialFilterCutoff));
    XCTAssertEqual(-12000, state.unmodulated(Index::delayModulatorLFO));
    XCTAssertEqual(-12000, state.unmodulated(Index::delayVibratoLFO));
    XCTAssertEqual(-12000, state.unmodulated(Index::attackModulatorEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::holdModulatorEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::decayModulatorEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::releaseModulatorEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::delayVolumeEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::attackVolumeEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::holdVolumeEnvelope));
    XCTAssertEqual(-12000, state.unmodulated(Index::decayVolumeEnvelope));
    XCTAssertEqual(2041, state.unmodulated(Index::releaseVolumeEnvelope));

    XCTAssertEqual(-1, state.unmodulated(Index::forcedMIDIKey));
    XCTAssertEqual(-1, state.unmodulated(Index::forcedMIDIVelocity));
    XCTAssertEqual(100, state.unmodulated(Index::scaleTuning));
    XCTAssertEqual(-1, state.unmodulated(Index::overridingRootKey));
}

@end
