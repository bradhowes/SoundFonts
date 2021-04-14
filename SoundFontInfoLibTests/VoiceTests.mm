// Copyright © 2020 Brad Howes. All rights reserved.

#import <AVFoundation/AVFoundation.h>

#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "IO/File.hpp"
#include "Render/Preset.hpp"
#include "Render/Voice/Voice.hpp"

using namespace SF2;

static NSArray<NSURL*>* urls = SF2Files.allResources;

using namespace SF2::Render;

@interface VoiceTests : XCTestCase <AVAudioPlayerDelegate>
@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, retain) XCTestExpectation* expectation;

@end

@implementation VoiceTests

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self.expectation fulfill];
}

- (void)testRolandPianoRender {

    NSURL* url = [urls objectAtIndex:3];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);

    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[0]);

    auto found = preset.find(69, 127);
    Voice voice1{44100, found[0]};

    found = preset.find(73, 127);
    Voice voice2{44100, found[0]};

    found = preset.find(76, 127);
    Voice voice3{44100, found[0]};

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

    for (auto index = 0; index < sampleCount / 3; ++index) {
        AUValue sample = voice1.render();
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == int(sampleCount / 4)) {
            voice1.keyReleased();
        }
    }

    for (auto index = 0; index < sampleCount / 3; ++index) {
        AUValue sample = voice2.render();
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == int(sampleCount / 4)) {
            voice2.keyReleased();
        }
    }

    for (auto index = 0; index < sampleCount / 3; ++index) {
        AUValue sample = voice3.render();
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == int(sampleCount / 4)) {
            voice3.keyReleased();
        }
    }

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
    NSURL* url = [urls objectAtIndex:2];
    uint64_t fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil] fileSize];
    int fd = ::open(url.path.UTF8String, O_RDONLY);
    auto file = IO::File(fd, fileSize);
    // file.dump();

    InstrumentCollection instruments(file);
    Preset preset(file, instruments, file.presets()[19]);

    auto found = preset.find(52, 127);
    Voice voice1{44100, found[0]};

    found = preset.find(56, 127);
    Voice voice2{44100, found[0]};

    found = preset.find(59, 127);
    Voice voice3{44100, found[0]};

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

    for (auto index = 0; index < sampleCount; ++index) {
        AUValue sample = (voice1.render() + voice2.render() + voice3.render()) / 3.0;
        *samplesLeft++ = sample;
        *samplesRight++ = sample;
        if (index == int(sampleRate * 0.7)) {
            voice1.keyReleased();
            voice2.keyReleased();
            voice3.keyReleased();
        }
    }

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
