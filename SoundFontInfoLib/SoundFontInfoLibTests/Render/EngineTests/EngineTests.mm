// Copyright © 2020 Brad Howes. All rights reserved.

#import <AVFoundation/AVFoundation.h>
#import <iostream>

#import <XCTest/XCTest.h>
#import <SF2Files/SF2Files-Swift.h>

#include "Render/Engine/Engine.hpp"
#import "SampleBasedContexts.hpp"

using namespace SF2;
using namespace SF2::Render::Engine;

@interface EngineTests : XCTestCase <AVAudioPlayerDelegate>
@property (nonatomic) bool playAudio;
@property (nonatomic, retain) AVAudioPlayer* player;
@property (nonatomic, retain) XCTestExpectation* expectation;
@property (nonatomic, retain) NSURL* audioFileURL;
@end

@implementation EngineTests {
  SampleBasedContexts contexts;
}

- (void)setUp {
#ifdef PLAY_AUDIO // See Development.xcconfig
  self.playAudio = YES;
#else
  self.playAudio = NO;
#endif
}

- (void)testInit {
  Engine<32> engine(44100.0);
  XCTAssertEqual(engine.maxVoiceCount, 32);
  XCTAssertEqual(engine.activeVoiceCount(), 0);
}

- (void)testLoad {
  Engine<32> engine(44100.0);
  engine.load(contexts.context0.file());
  XCTAssertEqual(engine.presetCount(), 235);
}

- (void)testUsePreset {
  Engine<32> engine(44100.0);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  [[NSFileManager defaultManager] removeItemAtPath:[self.audioFileURL path]  error:NULL];
  [self.expectation fulfill];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
  [[NSFileManager defaultManager] removeItemAtPath:[self.audioFileURL path]  error:NULL];
}

- (void)testRolandPianoChordRender {
  Float sampleRate{44100.0};
  Engine<32> engine{sampleRate};

  engine.load(contexts.context3.file());
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];

  AUAudioFrameCount frameCount = 512;
  engine.setRenderingFormat(format, frameCount);

  int seconds = 6;
  int sampleCount = sampleRate * seconds;
  int frames = sampleCount / frameCount;
  int remaining = sampleCount - frames * frameCount;
  int noteOnFrame = 10;
  int noteOnDuration = 50;
  int noteOffFrame = noteOnFrame + noteOnDuration;

  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
  assert(buffer != nullptr);

  AudioBufferList* bufferList = buffer.mutableAudioBufferList;
  bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(float);
  bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(float);

  float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
  float* samplesRight = (float*)(bufferList->mBuffers[1].mData);

  XCTAssertEqual(0, engine.activeVoiceCount());

  int frameIndex = 0;
  auto renderUntil = [&](int until) {
    while (frameIndex++ < until) {
      engine.render(samplesLeft, samplesRight, frameCount);
      samplesLeft += frameCount;
      samplesRight += frameCount;
    }
  };

  auto playChord = [&](int note1, int note2, int note3) {
    renderUntil(noteOnFrame);
    engine.noteOn(note1, 64);
    engine.noteOn(note2, 64);
    engine.noteOn(note3, 64);
    renderUntil(noteOffFrame);
    engine.noteOff(note1);
    engine.noteOff(note2);
    engine.noteOff(note3);
    noteOnFrame += noteOnDuration;
    noteOffFrame += noteOnDuration;
  };

  playChord(60, 64, 67);
  playChord(60, 65, 69);
  playChord(60, 64, 67);
  playChord(59, 62, 67);
  playChord(60, 64, 67);

  renderUntil(frameCount);
  if (remaining > 0) {
    engine.render(samplesLeft, samplesRight, remaining);
    samplesLeft += remaining;
    samplesRight += remaining;
  }

  XCTAssertEqual(2, engine.activeVoiceCount());

  [self playSamples: buffer count: sampleCount];
}

- (void)testBrass2Render {
//  double epsilon = 0.000001;
//  const auto& file = contexts.context2.file();
//
//  MIDI::Channel channel;
//  InstrumentCollection instruments(file);
//  Preset preset(file, instruments, file.presets()[19]);
//
//  auto found = preset.find(52, 127);
//  XCTAssertEqual(found.size(), 2);
//  Voice::Voice v1L{44100, channel, 0};
//  v1L.configure(found[0]);
//  Voice::Voice v1R{44100, channel, 1};
//  v1R.configure(found[1]);
//
//  found = preset.find(56, 127);
//  XCTAssertEqual(found.size(), 2);
//  Voice::Voice v2L{44100, channel, 2};
//  v2L.configure(found[0]);
//  Voice::Voice v2R{44100, channel, 3};
//  v2R.configure(found[1]);
//
//  found = preset.find(59, 127);
//  XCTAssertEqual(found.size(), 2);
//  Voice::Voice v3L{44100, channel, 4};
//  v3L.configure(found[0]);
//  Voice::Voice v3R{44100, channel, 5};
//  v3R.configure(found[1]);
//
//  double sampleRate = 44100.0;
//  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sampleRate channels:2];
//
//  int seconds = 10;
//  int sampleCount = sampleRate * seconds;
//  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:sampleCount];
//  AudioBufferList* bufferList = buffer.mutableAudioBufferList;
//  bufferList->mBuffers[0].mDataByteSize = sampleCount * sizeof(Float);
//  bufferList->mBuffers[1].mDataByteSize = sampleCount * sizeof(Float);
//  float* samplesLeft = (float*)(bufferList->mBuffers[0].mData);
//  float* samplesRight = (float*)(bufferList->mBuffers[1].mData);
//
//  std::vector<AUValue> samples;
//  for (auto index = 0; index < sampleCount; ++index) {
//    auto s1L = v1L.renderr();
//    auto s2L = v2L.renderr();
//    auto s3L = v3L.renderr();
//
//    auto s1R = v1R.renderr();
//    auto s2R = v2R.renderr();
//    auto s3R = v3R.renderr();
//
//    AUValue sL = (s1L + s2L + s3L) / 3.0;
//    AUValue sR = (s1R + s2R + s3R) / 3.0;
//
//    *samplesLeft++ = sL;
//    *samplesRight++ = sR;
//
//    if (index == 0 || index == sampleCount - 1) {
//      samples.push_back(s1L);
//      samples.push_back(s2L);
//      samples.push_back(s3L);
//    }
//    else if (index == int(sampleCount * 0.3)) {
//      // Enable vibrato
//      v1L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
//      v1R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
//      v2L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
//      v2R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
//      v3L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
//      v3R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 100);
//    }
//    else if (index == int(sampleCount * 0.5)) {
//      // Disable vibrato
//      v1L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
//      v1R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
//      v2L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
//      v2R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
//      v3L.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
//      v3R.state().setValue(Voice::State::State::Index::vibratoLFOToPitch, 0);
//    }
//    else if (index == int(sampleCount * 0.7)) {
//      samples.push_back(s1L);
//      samples.push_back(s2L);
//      samples.push_back(s3L);
//
//      v1L.keyReleased();
//      v1R.keyReleased();
//      v2L.keyReleased();
//      v2R.keyReleased();
//      v3L.keyReleased();
//      v3R.keyReleased();
//    }
//  }
//
//  XCTAssertEqual(9, samples.size());
//  XCTAssertEqualWithAccuracy(0.0, samples[0], epsilon);
//  XCTAssertEqualWithAccuracy(0.0, samples[1], epsilon);
//  XCTAssertEqualWithAccuracy(0.0, samples[2], epsilon);
//
//  XCTAssertEqualWithAccuracy(0.045224, samples[3], epsilon);
//  XCTAssertEqualWithAccuracy(0.077737, samples[4], epsilon);
//  XCTAssertEqualWithAccuracy(-0.045403, samples[5], epsilon);
//
//  XCTAssertEqualWithAccuracy(0.0, samples[6], epsilon);
//  XCTAssertEqualWithAccuracy(0.0, samples[7], epsilon);
//  XCTAssertEqualWithAccuracy(0.0, samples[8], epsilon);
//
//  [self playSamples: buffer count: sampleCount];
}

- (void)playSamples:(AVAudioPCMBuffer*)buffer count:(int)sampleCount
{
  if (!self.playAudio) return;

  buffer.frameLength = sampleCount;

  NSError* error = nil;
  self.audioFileURL = [NSURL fileURLWithPath: [self pathForTemporaryFile] isDirectory:NO];
  AVAudioFile* audioFile = [[AVAudioFile alloc] initForWriting:self.audioFileURL
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

  self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.audioFileURL error:&error];
  if (self.player == nullptr && error != nullptr) {
    XCTFail(@"Expectation Failed with error: %@", error);
    return;
  }

  self.player.delegate = self;
  self.expectation = [self expectationWithDescription:@"AVAudioPlayer finished"];
  [self.player play];
  [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *err) {
    if (err) {
      XCTFail(@"Expectation Failed with error: %@", err);
    }
  }];
}

- (NSString *)pathForTemporaryFile
{
  NSString *  result;
  CFUUIDRef   uuid;
  CFStringRef uuidStr;

  uuid = CFUUIDCreate(NULL);
  assert(uuid != NULL);

  uuidStr = CFUUIDCreateString(NULL, uuid);
  assert(uuidStr != NULL);

  result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf", uuidStr]];
  assert(result != nil);

  CFRelease(uuidStr);
  CFRelease(uuid);

  return result;
}

@end
