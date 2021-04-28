// Copyright © 2020 Brad Howes. All rights reserved.

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "Entity/Generator/Index.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "Render/Voice/State.hpp"

using namespace SF2;
using namespace SF2::Render;
using namespace SF2::Entity::Generator;

static NSArray<NSURL*>* urls = SF2Files.allResources;
static MIDI::Channel channel;

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

- (void)testKey {
    Voice::State state(44100.0, channel, 64, 32);
    state.setValue(Index::forcedMIDIKey, 128);
    XCTAssertEqual(64, state.eventKey());
    XCTAssertEqual(128, state.key());
}

- (void)testVelocity {
    Voice::State state(44100.0, channel, 64, 32);
    state.setValue(Index::forcedMIDIVelocity, 128);
    XCTAssertEqual(32, state.eventVelocity());
    XCTAssertEqual(128, state.velocity());
}

- (void)testEnvelopeSustainLevel {
    double epsilon = 0.000001;
    Voice::State state(44100.0, channel, 64, 32);

    state.setValue(Index::sustainVolumeEnvelope, 0);
    XCTAssertEqualWithAccuracy(1.0, state.sustainLevelVolumeEnvelope(), epsilon);
    state.setValue(Index::sustainVolumeEnvelope, 100);
    XCTAssertEqualWithAccuracy(0.9, state.sustainLevelVolumeEnvelope(), epsilon);
    state.setValue(Index::sustainVolumeEnvelope, 500);
    XCTAssertEqualWithAccuracy(0.5, state.sustainLevelVolumeEnvelope(), epsilon);
    state.setValue(Index::sustainVolumeEnvelope, 900);
    XCTAssertEqualWithAccuracy(0.1, state.sustainLevelVolumeEnvelope(), epsilon);
}

- (void)testKeyedEnvelopeModulator {
    Voice::State state(44100.0, channel, 60, 32);

    // 1s hold duration
    state.setValue(Index::holdVolumeEnvelope, 0);
    // Track keyboard such that octave increase results in 0.5 x hold duration
    state.setValue(Index::midiKeyToVolumeEnvelopeHold, 100);
    // For key 60 there is no scaling so no adjustment to hold duration
    state.setValue(Index::forcedMIDIKey, 60);
    XCTAssertEqualWithAccuracy(0.0, state.keyedVolumeEnvelopeHold(), 0.000001);
    XCTAssertEqualWithAccuracy(1.0, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                        state.keyedVolumeEnvelopeHold()), 0.001);

    // An octave increase should halve the duration.
    state.setValue(Index::forcedMIDIKey, 72);
    XCTAssertEqualWithAccuracy(-1200.0, state.keyedVolumeEnvelopeHold(), 0.000001);
    XCTAssertEqualWithAccuracy(0.5, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                        state.keyedVolumeEnvelopeHold()), 0.001);

    // An octave decrease should double the duration.
    state.setValue(Index::forcedMIDIKey, 48);
    XCTAssertEqualWithAccuracy(1200.0, state.keyedVolumeEnvelopeHold(), 0.000001);
    XCTAssertEqualWithAccuracy(2.0, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                        state.keyedVolumeEnvelopeHold()), 0.001);

    // Validate spec scenario
    state.setValue(Index::forcedMIDIKey, 36);
    state.setValue(Index::midiKeyToVolumeEnvelopeHold, 50);
    state.setValue(Index::holdVolumeEnvelope, -7973);
    XCTAssertEqualWithAccuracy(1200.0, state.keyedVolumeEnvelopeHold(), 0.000001);
    XCTAssertEqualWithAccuracy(0.02, DSP::centsToSeconds(state.modulated(Index::holdVolumeEnvelope) +
                                                         state.keyedVolumeEnvelopeHold()), 0.001);
}

@end
