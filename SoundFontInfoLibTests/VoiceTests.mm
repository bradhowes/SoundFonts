// Copyright © 2020 Brad Howes. All rights reserved.

#import <AVFoundation/AVFoundation.h>

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#import "IO/File.hpp"
#import "MIDI/Channel.hpp"
#import "Render/Preset.hpp"
#import "Render/Voice/Voice.hpp"

using namespace SF2;
using namespace SF2::Render;

static NSArray<NSURL*>* urls = SF2Files.allResources;

@interface VoiceTests : XCTestCase <AVAudioPlayerDelegate>
@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, retain) XCTestExpectation* expectation;
@end

@implementation VoiceTests

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self.expectation fulfill];
}

- (void)testRolandPianoRender {
    double epsilon = 0.000001;

    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    MIDI::Channel channel;
    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);

    auto found = preset.find(69, 127);
    Voice::Voice voice1{44100, channel, found[0]};

    found = preset.find(73, 127);
    Voice::Voice voice2{44100, channel, found[0]};

    found = preset.find(76, 127);
    Voice::Voice voice3{44100, channel, found[0]};

    double sampleRate = 44100.0;
    AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];

    int seconds = 1;
    int sampleCount = sampleRate * seconds;
    AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
    AudioBufferList* bufferList = buffer.mutableAudioBufferList;
    bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(float);
    bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(float);
    float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
    float* samplesRight = (float*)(bufferList->mBuffers[1].mData);

    size_t keyReleaseCount{size_t(sampleCount / 4)};
    size_t voiceSampleCount{size_t(sampleCount / 3)};
    std::vector<AUValue> samples;
    for (auto index = 0; index < voiceSampleCount; ++index) {
        AUValue sample = voice1.render();
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == 0 || index == voiceSampleCount - 1) {
            samples.push_back(sample);
        }
        else if (index == keyReleaseCount) {
            samples.push_back(sample);
            voice1.keyReleased();
        }
    }

    for (auto index = 0; index < voiceSampleCount; ++index) {
        AUValue sample = voice2.render();
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == 0 || index == voiceSampleCount - 1) {
            samples.push_back(sample);
        }
        else if (index == int(sampleCount / 4)) {
            samples.push_back(sample);
            voice2.keyReleased();
        }
    }

    for (auto index = 0; index < voiceSampleCount; ++index) {
        AUValue sample = voice3.render();
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == 0 || index == voiceSampleCount - 1) {
            samples.push_back(sample);
        }
        else if (index == keyReleaseCount) {
            samples.push_back(sample);
            voice3.keyReleased();
        }
    }

    XCTAssertEqual(9, samples.size());
    XCTAssertEqualWithAccuracy( 0.000000, samples[0], epsilon);
    XCTAssertEqualWithAccuracy( 0.293332, samples[1], epsilon);
    XCTAssertEqualWithAccuracy(-0.259781, samples[2], epsilon);
    XCTAssertEqualWithAccuracy( 0.000000, samples[3], epsilon);
    XCTAssertEqualWithAccuracy( 0.128983, samples[4], epsilon);
    XCTAssertEqualWithAccuracy(-0.146351, samples[5], epsilon);
    XCTAssertEqualWithAccuracy( 0.000000, samples[6], epsilon);
    XCTAssertEqualWithAccuracy(-0.218109, samples[7], epsilon);
    XCTAssertEqualWithAccuracy(-0.063845, samples[8], epsilon);

    return; // REMOVE to hear the audio

    buffer.frameLength = sampleCount;

    NSError* error = nil;
    NSURL* fileURL = [NSURL fileURLWithPath:@"/Users/howes/samplesRolandPiano.caf" isDirectory:NO];
    AVAudioFile* audioFile = [[AVAudioFile alloc] initForWriting:fileURL
                                                        settings:[[buffer format] settings]
                                                    commonFormat:AVAudioPCMFormatFloat32
                                                     interleaved:false
                                                           error:&error];
    if (error) {
        XCTFail(@"failed with error: %@", error);
        return;
    }

    [audioFile writeFromBuffer:buffer error:&error];
    if (error) {
        XCTFail(@"failed with error: %@", error);
        return;
    }

    audioFile = nil;

    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (self.player == nullptr && error != nullptr) {
        XCTFail(@"Expectation Failed with error: %@", error);
        return;
    }

    self.player.delegate = self;
    self.expectation = [self expectationWithDescription:@"AVAudioPlayer finished"];
    [self.player play];
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testBrass2Render {
    double epsilon = 0.000001;

    NSURL* url = [urls objectAtIndex:2];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);
    // file.dumpThreaded();

    MIDI::Channel channel;
    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[19]);

    auto found = preset.find(52, 127);
    Voice::Voice voice1{44100, channel, found[0]};

    found = preset.find(56, 127);
    Voice::Voice voice2{44100, channel, found[0]};

    found = preset.find(59, 127);
    Voice::Voice voice3{44100, channel, found[0]};

    double sampleRate = 44100.0;
    AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];

    int seconds = 10;
    int sampleCount = sampleRate * seconds;
    AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
    AudioBufferList* bufferList = buffer.mutableAudioBufferList;
    bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(float);
    bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(float);
    float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
    float* samplesRight = (float*)(bufferList->mBuffers[1].mData);

    std::vector<AUValue> samples;
    for (auto index = 0; index < sampleCount; ++index) {
        auto s1 = voice1.render();
        auto s2 = voice2.render();
        auto s3 = voice3.render();

        AUValue sample = (s1 + s2 + s3) / 3.0;
        *samplesLeft++ = sample;
        *samplesRight++ = sample;

        if (index == 0 || index == sampleCount - 1) {
            samples.push_back(s1);
            samples.push_back(s2);
            samples.push_back(s3);
        }
        else if (index == int(sampleCount * 0.7)) {
            samples.push_back(s1);
            samples.push_back(s2);
            samples.push_back(s3);

            voice1.keyReleased();
            voice2.keyReleased();
            voice3.keyReleased();
        }
    }

    XCTAssertEqual(9, samples.size());
    XCTAssertEqualWithAccuracy(0.0, samples[0], epsilon);
    XCTAssertEqualWithAccuracy(0.0, samples[1], epsilon);
    XCTAssertEqualWithAccuracy(0.0, samples[2], epsilon);

    XCTAssertEqualWithAccuracy(-0.239043, samples[3], epsilon);
    XCTAssertEqualWithAccuracy(-0.045543, samples[4], epsilon);
    XCTAssertEqualWithAccuracy( 0.016368, samples[5], epsilon);

    XCTAssertEqualWithAccuracy(0.0, samples[6], epsilon);
    XCTAssertEqualWithAccuracy(0.0, samples[7], epsilon);
    XCTAssertEqualWithAccuracy(0.0, samples[8], epsilon);

    return; // REMOVE to hear the audio

    buffer.frameLength = sampleCount;

    NSError* error = nil;
    NSURL* fileURL = [NSURL fileURLWithPath:@"/Users/howes/samplesBrass2.caf" isDirectory:NO];
    AVAudioFile* audioFile = [[AVAudioFile alloc] initForWriting:fileURL
                                                        settings:[[buffer format] settings]
                                                    commonFormat:AVAudioPCMFormatFloat32
                                                     interleaved:false
                                                           error:&error];
    if (error) {
        XCTFail(@"failed with error: %@", error);
        return;
    }

    [audioFile writeFromBuffer:buffer error:&error];
    if (error) {
        XCTFail(@"failed with error: %@", error);
        return;
    }

    audioFile = nil;

    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (self.player == nullptr && error != nullptr) {
        XCTFail(@"Expectation Failed with error: %@", error);
        return;
    }

    self.player.delegate = self;
    self.expectation = [self expectationWithDescription:@"AVAudioPlayer finished"];
    [self.player play];
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

@end
